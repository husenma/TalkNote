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
    @Published var hasRequestedPermissions: Bool = false
    
    private var permissionCheckTimer: Timer?
    
    init() {
        checkCurrentPermissions()
        setupPermissionMonitoring()
    }
    
    deinit {
        permissionCheckTimer?.invalidate()
    }
    
    /// Set up continuous permission monitoring
    private func setupPermissionMonitoring() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkCurrentPermissions()
            }
        }
    }
    
    /// Check current permission states
    func checkCurrentPermissions() {
        let newMicPermission: AVAudioSession.RecordPermission
        if #available(iOS 17.0, *) {
            newMicPermission = AVAudioApplication.shared.recordPermission
        } else {
            newMicPermission = AVAudioSession.sharedInstance().recordPermission
        }
        
        let newSpeechPermission = SFSpeechRecognizer.authorizationStatus()
        
        if microphonePermission != newMicPermission || speechPermission != newSpeechPermission {
            microphonePermission = newMicPermission
            speechPermission = newSpeechPermission
            updatePermissionsStatus()
            
            // Debug log permission changes
            PermissionDebugger.shared.logPermissionStates()
        }
    }
    
    /// Validate permissions before any audio operation
    func validatePermissionsForAudioOperation() -> Bool {
        checkCurrentPermissions()
        return allPermissionsGranted
    }
    
    /// Check if all required permissions are granted
    var allPermissionsGranted: Bool {
        let micPermissionGranted: Bool
        if #available(iOS 17.0, *) {
            micPermissionGranted = microphonePermission == .granted
        } else {
            micPermissionGranted = microphonePermission == .granted
        }
        
        return micPermissionGranted && speechPermission == .authorized
    }
    
    /// Request all required permissions sequentially
    func requestAllPermissions() async {
        hasRequestedPermissions = true
        
        await requestMicrophonePermission()
        if microphonePermission == .granted {
            await requestSpeechPermission()
        }
        
        // Give some time for permission changes to propagate
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        checkCurrentPermissions()
        
        if !permissionsGranted && hasRequestedPermissions {
            showingPermissionAlert = true
        }
    }
    
    /// Request microphone permission
    private func requestMicrophonePermission() async {
        return await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    Task { @MainActor in
                        self.microphonePermission = granted ? .granted : .denied
                        self.updatePermissionsStatus()
                        continuation.resume()
                    }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    Task { @MainActor in
                        self.microphonePermission = granted ? .granted : .denied
                        self.updatePermissionsStatus()
                        continuation.resume()
                    }
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
