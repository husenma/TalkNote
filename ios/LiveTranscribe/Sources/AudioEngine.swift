import AVFoundation

final class AudioEngine {
    private lazy var engine = AVAudioEngine()
    private let bus = 0
    private var isEngineStarted = false

    func startStreaming(onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        // First check if we have microphone permission
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            print("Microphone permission not granted")
            return
        }
        
        // Ensure we have a fresh engine if needed
        if !isEngineStarted {
            engine = AVAudioEngine()
        }
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: bus)

        // Remove any existing tap first
        if input.numberOfTaps > 0 {
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
        if engine.inputNode.numberOfTaps > 0 {
            engine.inputNode.removeTap(onBus: bus)
        }
        
        if engine.isRunning {
            engine.stop()
        }
        
        isEngineStarted = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
