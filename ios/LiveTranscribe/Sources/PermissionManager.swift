import Foundation
import AVFoundation
import Speech
import UIKit

/// PermissionManager handles all app permissions and user authorization states
@MainActor
final class PermissionManager: ObservableObject {
    @Published var microphonePermission: AVAudioSession.RecordPermission = .undetermined
    @Published var speechPermission: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var permissionsGranted: Bool = false
    @Published var showingPermissionAlert: Bool = false
    
    init() {
        checkCurrentPermissions()
    }
    
    /// Check current permission states
    func checkCurrentPermissions() {
        microphonePermission = AVAudioSession.sharedInstance().recordPermission
        speechPermission = SFSpeechRecognizer.authorizationStatus()
        updatePermissionsStatus()
    }
    
    /// Request all required permissions sequentially
    func requestAllPermissions() async {
        await requestMicrophonePermission()
        if microphonePermission == .granted {
            await requestSpeechPermission()
        }
        
        if !permissionsGranted {
            showingPermissionAlert = true
        }
    }
    
    /// Request microphone permission
    private func requestMicrophonePermission() async {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.microphonePermission = granted ? .granted : .denied
                    self.updatePermissionsStatus()
                    continuation.resume()
                }
            }
        }
    }
    
    /// Request speech recognition permission
    private func requestSpeechPermission() async {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.speechPermission = status
                    self.updatePermissionsStatus()
                    continuation.resume()
                }
            }
        }
    }
    
    /// Update the overall permissions status
    private func updatePermissionsStatus() {
        permissionsGranted = (microphonePermission == .granted) && (speechPermission == .authorized)
    }
    
    /// Check if all required permissions are granted
    var allPermissionsGranted: Bool {
        return microphonePermission == .granted && speechPermission == .authorized
    }
    
    /// Get detailed permission status description
    var permissionStatusDescription: String {
        switch (microphonePermission, speechPermission) {
        case (.granted, .authorized):
            return "All permissions granted ✓"
        case (.denied, _), (_, .denied):
            return "Permissions denied - Tap to open Settings"
        case (.undetermined, _), (_, .notDetermined):
            return "Tap to grant required permissions"
        default:
            return "Grant microphone and speech permissions"
        }
    }
    
    /// Get short status for UI
    var shortPermissionStatus: String {
        if allPermissionsGranted {
            return "Ready to record"
        } else {
            return "Permissions needed"
        }
    }
    
    /// Check if permissions were explicitly denied
    var permissionsDenied: Bool {
        return microphonePermission == .denied || speechPermission == .denied
    }
    
    /// Open app settings for manual permission management
    func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// Show permission explanation alert
    func showPermissionExplanation() -> (title: String, message: String) {
        let title = "Permissions Required"
        let message = """
        TalkNote needs these permissions to work properly:
        
        🎤 Microphone: To capture your voice for transcription
        🗣️ Speech Recognition: To convert speech to text accurately
        
        Your privacy is protected - audio is only used for translation and not stored permanently.
        """
        return (title, message)
    }
}
