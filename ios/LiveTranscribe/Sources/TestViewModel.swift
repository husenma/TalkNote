import SwiftUI
import Foundation
import AVFoundation  
import Speech

// Simplified test to check class structure
@MainActor
class TestTranscriptionViewModel: ObservableObject {
    @Published var isTranscribing = false
    @Published var displayText = ""
    
    private let thermalManager = ThermalManager()
    private let whisperKitService = WhisperKitService()
    
    func start() async {
        isTranscribing = true
    }
    
    func stop() async {
        isTranscribing = false
    }
}
