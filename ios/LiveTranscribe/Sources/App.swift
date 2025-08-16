import SwiftUI
import AVFoundation
import Speech

@main
struct LiveTranscribeApp: App {
    init() {
        // Debug permission states on app launch
        PermissionDebugger.shared.logPermissionStates()
        PermissionDebugger.shared.validateInfoPlistKeys()
        
        // Request permissions immediately on app launch
        Task {
            await requestPermissionsImmediately()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    @MainActor
    private func requestPermissionsImmediately() async {
        // Request microphone permission first
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("📱 Microphone permission: \(granted ? "Granted" : "Denied")")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("📱 Microphone permission: \(granted ? "Granted" : "Denied")")
            }
        }
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { status in
            print("🗣️ Speech recognition permission: \(status)")
        }
    }
}
