import AVFoundation

final class AudioEngine {
    private lazy var engine = AVAudioEngine()
    private let bus = 0
    private var isEngineStarted = false
    private var effectsChain: [AVAudioUnit] = []

    func startStreaming(onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        startStreamingWithEnhancedSettings(sensitivity: 0.8, noiseReduction: false, onBuffer: onBuffer)
    }
    
    func startStreamingWithEnhancedSettings(
        sensitivity: Float,
        noiseReduction: Bool,
        onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) {
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

        // Remove any existing tap first
        if input.inputFormat(forBus: bus).channelCount > 0 {
            input.removeTap(onBus: bus)
        }
        
        // Configure enhanced audio processing
        if noiseReduction {
            setupNoiseReduction(input: input, format: format)
        }
        
        // Adjust buffer size based on sensitivity
        let bufferSize = sensitivity > 0.7 ? AVAudioFrameCount(1024) : AVAudioFrameCount(2048)

        input.installTap(onBus: bus, bufferSize: bufferSize, format: format) { buffer, when in
            // Apply sensitivity adjustment
            if sensitivity != 1.0 {
                self.adjustAudioSensitivity(buffer: buffer, sensitivity: sensitivity)
            }
            onBuffer(buffer, when)
        }

        do {
            // Enhanced audio session configuration
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, 
                                       mode: .measurement, 
                                       options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            
            // Set preferred settings for high-quality recording
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms for low latency
            try audioSession.setPreferredInputNumberOfChannels(1)
            
            // Enable measurement mode for better accuracy
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            if !engine.isRunning {
                try engine.start()
                isEngineStarted = true
                print("Enhanced audio engine started with sensitivity: \(sensitivity), noise reduction: \(noiseReduction)")
            }
        } catch {
            print("Enhanced audio start error: \(error)")
            isEngineStarted = false
        }
    }
    
    private func setupNoiseReduction(input: AVAudioInputNode, format: AVAudioFormat) {
        // Create noise reduction unit using available iOS audio unit
        let noiseSuppression = AVAudioUnitEffect(audioComponentDescription: 
            AudioComponentDescription(
                componentType: kAudioUnitType_Effect,
                componentSubType: kAudioUnitSubType_NBandEQ, // Use equalizer for noise filtering
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0
            )
        )
        
        // Attach and connect noise reduction
        engine.attach(noiseSuppression)
        engine.connect(input, to: noiseSuppression, format: format)
        effectsChain.append(noiseSuppression)
    }
    
    private func adjustAudioSensitivity(buffer: AVAudioPCMBuffer, sensitivity: Float) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameLength {
                samples[frame] *= sensitivity
            }
        }
    }

    func stop() {
        // Remove effects chain
        for effect in effectsChain {
            engine.detach(effect)
        }
        effectsChain.removeAll()
        
        // Safely remove tap
        engine.inputNode.removeTap(onBus: bus)
        
        if engine.isRunning {
            engine.stop()
        }
        
        isEngineStarted = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // Get current audio levels for UI feedback
    func getCurrentAudioLevel() -> Float {
        guard isEngineStarted else { return 0.0 }
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: bus)
        
        // This is a simplified version - in a real implementation,
        // you'd need to sample the current audio buffer
        return 0.5 // Placeholder
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
    
    // MARK: - WhisperKit Support
    
    func startStreamingForWhisperKit() throws -> AsyncStream<Data> {
        return AsyncStream<Data> { continuation in
            do {
                // Configure audio session for WhisperKit (16kHz mono)
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true)
                
                let inputNode = engine.inputNode
                let inputFormat = inputNode.inputFormat(forBus: bus)
                
                // WhisperKit requires 16kHz, mono, 16-bit PCM
                guard let whisperFormat = AVAudioFormat(
                    commonFormat: .pcmFormatInt16,
                    sampleRate: 16000,
                    channels: 1,
                    interleaved: false
                ) else {
                    continuation.finish()
                    return
                }
                
                // Install tap to convert audio to WhisperKit format
                inputNode.installTap(onBus: bus, bufferSize: 1024, format: whisperFormat) { buffer, time in
                    // Convert buffer to Data for WhisperKit
                    guard let channelData = buffer.int16ChannelData?[0] else { return }
                    let frameCount = Int(buffer.frameLength)
                    let data = Data(bytes: channelData, count: frameCount * 2) // 2 bytes per Int16 sample
                    continuation.yield(data)
                }
                
                engine.prepare()
                try engine.start()
                isEngineStarted = true
                
                // Handle termination
                continuation.onTermination = { _ in
                    self.engine.stop()
                    inputNode.removeTap(onBus: self.bus)
                    self.isEngineStarted = false
                }
                
            } catch {
                continuation.finish()
            }
        }
    }
}
