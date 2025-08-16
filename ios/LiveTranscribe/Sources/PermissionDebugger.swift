import Foundation
import AVFoundation
import Speech
import UIKit

/// Debug utility for diagnosing permission issues
final class PermissionDebugger {
    static let shared = PermissionDebugger()
    
    private init() {}
    
    func logPermissionStates() {
        print("🔍 PERMISSION DEBUG:")
        print("  📱 Microphone Permission: \(microphoneStatusString)")
        print("  🗣️ Speech Recognition: \(speechRecognitionStatusString)")
        print("  ✅ All Granted: \(allPermissionsGranted)")
        
        if !allPermissionsGranted {
            print("  ⚠️ Missing Permissions Detected!")
            logRequiredInfoPlistKeys()
        }
    }
    
    private var microphoneStatusString: String {
        let permission: UnifiedRecordPermission
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined: permission = .undetermined
            case .granted: permission = .granted
            case .denied: permission = .denied
            @unknown default: permission = .undetermined
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined: permission = .undetermined
            case .granted: permission = .granted
            case .denied: permission = .denied
            @unknown default: permission = .undetermined
            }
        }
        
        switch permission {
        case .undetermined: return "Undetermined"
        case .granted: return "Granted ✅"
        case .denied: return "Denied ❌"
        }
    }
    
    private var speechRecognitionStatusString: String {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined: return "Not Determined"
        case .authorized: return "Authorized ✅"
        case .denied: return "Denied ❌"
        case .restricted: return "Restricted ❌"
        @unknown default: return "Unknown"
        }
    }
    
    private var allPermissionsGranted: Bool {
        let micPermission: UnifiedRecordPermission
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined: micPermission = .undetermined
            case .granted: micPermission = .granted
            case .denied: micPermission = .denied
            @unknown default: micPermission = .undetermined
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined: micPermission = .undetermined
            case .granted: micPermission = .granted
            case .denied: micPermission = .denied
            @unknown default: micPermission = .undetermined
            }
        }
        
        return micPermission == .granted && SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    private func logRequiredInfoPlistKeys() {
        print("  📋 Required Info.plist Keys:")
        print("     NSMicrophoneUsageDescription")
        print("     NSSpeechRecognitionUsageDescription")
    }
    
    func validateInfoPlistKeys() -> Bool {
        let bundle = Bundle.main
        let hasMicrophoneKey = bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil
        let hasSpeechKey = bundle.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil
        
        print("🔍 INFO.PLIST VALIDATION:")
        print("  🎤 NSMicrophoneUsageDescription: \(hasMicrophoneKey ? "✅ Present" : "❌ Missing")")
        print("  🗣️ NSSpeechRecognitionUsageDescription: \(hasSpeechKey ? "✅ Present" : "❌ Missing")")
        
        if hasMicrophoneKey {
            let micDesc = bundle.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String ?? ""
            print("     Content: \"\(micDesc)\"")
        }
        
        if hasSpeechKey {
            let speechDesc = bundle.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String ?? ""
            print("     Content: \"\(speechDesc)\"")
        }
        
        return hasMicrophoneKey && hasSpeechKey
    }
}
