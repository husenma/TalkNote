import AVFoundation

final class AudioEngine {
    private let engine = AVAudioEngine()
    private let bus = 0

    func startStreaming(onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        // First check if we have microphone permission
        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            print("Microphone permission not granted")
            return
        }
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: bus)

        input.installTap(onBus: bus, bufferSize: 2048, format: format) { buffer, when in
            onBuffer(buffer, when)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
        } catch {
            print("Audio start error: \(error)")
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: bus)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
