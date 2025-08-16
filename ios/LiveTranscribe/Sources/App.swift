import SwiftUI

@main
struct LiveTranscribeApp: App {
    init() {
        // Debug permission states on app launch
        PermissionDebugger.shared.logPermissionStates()
        PermissionDebugger.shared.validateInfoPlistKeys()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
