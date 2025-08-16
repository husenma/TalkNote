import SwiftUI
import AVFoundation
import Speech

/// Startup Permission Manager ensures permissions are granted before app functionality
@MainActor
final class StartupPermissionManager: ObservableObject {
    @Published var showingPermissionScreen = false
    @Published var permissionStep: PermissionStep = .microphone
    @Published var microphoneGranted = false
    @Published var speechGranted = false
    
    enum PermissionStep: CaseIterable {
        case microphone
        case speech
        case completed
        
        var title: String {
            switch self {
            case .microphone: return "Microphone Access"
            case .speech: return "Speech Recognition"
            case .completed: return "Ready to Go!"
            }
        }
        
        var description: String {
            switch self {
            case .microphone: return "TalkNote needs microphone access to record your voice for real-time translation"
            case .speech: return "Speech recognition converts your words into text for accurate translation"
            case .completed: return "All permissions granted! You're ready to start translating."
            }
        }
        
        var icon: String {
            switch self {
            case .microphone: return "mic.fill"
            case .speech: return "text.bubble.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    var allPermissionsGranted: Bool {
        return microphoneGranted && speechGranted
    }
    
    init() {
        checkInitialPermissions()
    }
    
    func checkInitialPermissions() {
        updatePermissionStates()
        showingPermissionScreen = !allPermissionsGranted
    }
    
    private func updatePermissionStates() {
        if #available(iOS 17.0, *) {
            microphoneGranted = AVAudioApplication.shared.recordPermission == .granted
        } else {
            microphoneGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        speechGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
    }
    
    func requestCurrentPermission() async {
        switch permissionStep {
        case .microphone:
            await requestMicrophonePermission()
            if microphoneGranted {
                permissionStep = .speech
            }
        case .speech:
            await requestSpeechPermission()
            if speechGranted {
                permissionStep = .completed
            }
        case .completed:
            showingPermissionScreen = false
        }
    }
    
    private func requestMicrophonePermission() async {
        return await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    Task { @MainActor in
                        self.microphoneGranted = granted
                        self.updatePermissionStates()
                        continuation.resume()
                    }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    Task { @MainActor in
                        self.microphoneGranted = granted
                        self.updatePermissionStates()
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    private func requestSpeechPermission() async {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.speechGranted = (status == .authorized)
                    self.updatePermissionStates()
                    continuation.resume()
                }
            }
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
