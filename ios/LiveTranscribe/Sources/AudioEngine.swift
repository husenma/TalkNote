import AVFoundation

final class AudioEngine {
    private lazy var engine = AVAudioEngine()
    private let bus = 0
    private var isEngineStarted = false

    func startStreaming(onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        // First check if we have microphone permission
        let hasPermission: Bool
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: hasPermission = true
            default: hasPermission = false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: hasPermission = true
            default: hasPermission = false
            }
        }
        
        guard hasPermission else {
            print("Microphone permission not granted")
            return
        }
        
        // Ensure we have a fresh engine if needed
        if !isEngineStarted {
            engine = AVAudioEngine()
        }
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: bus)

        // Remove any existing tap first - check if tap exists before removing
        if input.inputFormat(forBus: bus).channelCount > 0 {
            input.removeTap(onBus: bus)
        }

        input.installTap(onBus: bus, bufferSize: 2048, format: format) { buffer, when in
            onBuffer(buffer, when)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            if !engine.isRunning {
                try engine.start()
                isEngineStarted = true
            }
        } catch {
            print("Audio start error: \(error)")
            isEngineStarted = false
        }
    }

    func stop() {
        // Safely remove tap - AVAudioInputNode doesn't have numberOfTaps property
        // We'll safely remove the tap without try-catch since removeTap doesn't throw
        engine.inputNode.removeTap(onBus: bus)
        
        if engine.isRunning {
            engine.stop()
        }
        
        isEngineStarted = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // Backward compatibility methods
    func startRecording() async throws {
        try await withCheckedThrowingContinuation { continuation in
            startStreaming { buffer, time in
                // Just start streaming, resume continuation immediately
            }
            continuation.resume()
        }
    }
    
    func stopRecording() async {
        stop()
    }
}
