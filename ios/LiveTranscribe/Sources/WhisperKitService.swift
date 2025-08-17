import Foundation
import WhisperKit
import AVFoundation

/// WhisperKit service for high-accuracy on-device speech recognition
@MainActor
class WhisperKitService: ObservableObject {
    
    // MARK: - WhisperKit Models
    enum WhisperModel: String, CaseIterable, Identifiable {
        case tiny = "openai_whisper-tiny"
        case base = "openai_whisper-base" 
        case small = "openai_whisper-small"
        case medium = "openai_whisper-medium"
        case large = "openai_whisper-large-v3"
        case distilLarge = "distil-whisper_distil-large-v3"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .tiny: return "Tiny (Fast)"
            case .base: return "Base (Balanced)"  
            case .small: return "Small (Good)"
            case .medium: return "Medium (Better)"
            case .large: return "Large-v3 (Best)"
            case .distilLarge: return "Distil Large (Efficient)"
            }
        }
        
        var accuracy: String {
            switch self {
            case .tiny: return "85%"
            case .base: return "88%"
            case .small: return "92%"
            case .medium: return "95%"
            case .large: return "98%"
            case .distilLarge: return "97%"
            }
        }
        
        var description: String {
            switch self {
            case .tiny: return "Fastest, lowest memory usage"
            case .base: return "Good balance of speed and accuracy"
            case .small: return "Better accuracy, moderate speed"
            case .medium: return "High accuracy, slower processing"
            case .large: return "Highest accuracy, most resources"
            case .distilLarge: return "Near-large accuracy, faster speed"
            }
        }
        
        var memoryFootprint: String {
            switch self {
            case .tiny: return "39MB"
            case .base: return "74MB"
            case .small: return "244MB"
            case .medium: return "769MB"
            case .large: return "1.5GB"
            case .distilLarge: return "756MB"
            }
        }
    }
    
    // MARK: - Properties
    @Published var isInitialized = false
    @Published var isTranscribing = false
    @Published var currentText = ""
    @Published var segmentedText: [String] = []
    @Published var confidence: Float = 0.0
    @Published var processingTime: TimeInterval = 0.0
    @Published var selectedModel: WhisperModel = .base
    @Published var isModelLoading = false
    @Published var loadingProgress: Float = 0.0
    @Published var errorMessage: String?
    
    private var whisperKit: WhisperKit?
    private var audioProcessor: AudioProcessor?
    private var isStreamingActive = false
    
    // MARK: - Initialization
    
    init() {
        setupWhisperKit()
    }
    
    private func setupWhisperKit() {
        Task {
            await loadModel(selectedModel)
        }
    }
    
    // MARK: - Model Management
    
    func loadModel(_ model: WhisperModel) async {
        isModelLoading = true
        loadingProgress = 0.0
        errorMessage = nil
        
        do {
            let config = WhisperKitConfig(
                model: model.rawValue,
                computeOptions: WhisperKitConfig.ComputeOptions(),
                audioEncoderComputeUnits: .cpuAndGPU,
                textDecoderComputeUnits: .cpuAndGPU
            )
            
            // Update progress during model loading
            loadingProgress = 0.3
            
            whisperKit = try await WhisperKit(config)
            selectedModel = model
            
            loadingProgress = 0.8
            
            // Verify model is ready
            if whisperKit != nil {
                isInitialized = true
                loadingProgress = 1.0
                print("✅ WhisperKit loaded: \(model.displayName)")
            }
        } catch {
            errorMessage = "Failed to load model: \(error.localizedDescription)"
            print("❌ WhisperKit loading failed: \(error)")
        }
        
        isModelLoading = false
    }
    
    // MARK: - Transcription Methods
    
    func transcribeAudio(data: Data) async -> String? {
        guard let whisperKit = whisperKit, isInitialized else {
            errorMessage = "WhisperKit not initialized"
            return nil
        }
        
        let startTime = Date()
        
        do {
            // Convert audio data to temporary file for WhisperKit
            let tempURL = createTemporaryAudioFile(from: data)
            defer { try? FileManager.default.removeItem(at: tempURL) }
            
            // Transcribe audio
            let result = try await whisperKit.transcribe(audioPath: tempURL.path)
            
            processingTime = Date().timeIntervalSince(startTime)
            
            if let transcription = result {
                // Extract confidence if available
                confidence = transcription.avgLogprob ?? 0.0
                
                // Update segmented text for better UX
                segmentedText = transcription.segments.map { $0.text }
                
                currentText = transcription.text
                return transcription.text
            }
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            print("❌ WhisperKit transcription error: \(error)")
        }
        
        return nil
    }
    
    func startStreamingTranscription(audioData: AsyncStream<Data>) async {
        guard isInitialized else { return }
        
        isTranscribing = true
        isStreamingActive = true
        
        var audioBuffer = Data()
        let bufferSizeThreshold = 32000 // ~2 seconds at 16kHz
        
        for await chunk in audioData {
            guard isStreamingActive else { break }
            
            audioBuffer.append(chunk)
            
            // Process when we have enough audio data
            if audioBuffer.count >= bufferSizeThreshold {
                if let transcription = await transcribeAudio(data: audioBuffer) {
                    currentText = transcription
                }
                
                // Keep some overlap for better continuity
                let overlapSize = bufferSizeThreshold / 4
                audioBuffer = Data(audioBuffer.suffix(overlapSize))
            }
        }
        
        // Process remaining buffer
        if !audioBuffer.isEmpty {
            if let transcription = await transcribeAudio(data: audioBuffer) {
                currentText = transcription
            }
        }
        
        isTranscribing = false
    }
    
    func stopTranscription() {
        isStreamingActive = false
        isTranscribing = false
    }
    
    // MARK: - Audio Processing Helpers
    
    private func createTemporaryAudioFile(from data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFile = tempDirectory.appendingPathComponent("whisper_audio_\(UUID().uuidString).wav")
        
        // Convert raw audio data to WAV format for WhisperKit
        let wavData = createWAVHeader(for: data) + data
        try? wavData.write(to: tempFile)
        
        return tempFile
    }
    
    private func createWAVHeader(for audioData: Data) -> Data {
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let dataLength = UInt32(audioData.count)
        
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: dataLength + 36) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(16)) { Data($0) }) // chunk size
        header.append(withUnsafeBytes(of: UInt16(1)) { Data($0) })  // audio format (PCM)
        header.append(withUnsafeBytes(of: channels) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate * UInt32(channels * bitsPerSample / 8)) { Data($0) }) // byte rate
        header.append(withUnsafeBytes(of: channels * bitsPerSample / 8) { Data($0) }) // block align
        header.append(withUnsafeBytes(of: bitsPerSample) { Data($0) })
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: dataLength) { Data($0) })
        
        return header
    }
    
    // MARK: - Utility Methods
    
    func getAvailableModels() -> [WhisperModel] {
        return WhisperModel.allCases
    }
    
    func getModelInfo(_ model: WhisperModel) -> (accuracy: String, memory: String, description: String) {
        return (model.accuracy, model.memoryFootprint, model.description)
    }
    
    func resetTranscription() {
        currentText = ""
        segmentedText.removeAll()
        confidence = 0.0
        errorMessage = nil
    }
}

// MARK: - Audio Processor for Streaming
class AudioProcessor {
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    
    func setupAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func startRecording() -> AsyncStream<Data> {
        return AsyncStream { continuation in
            do {
                try setupAudioSession()
                
                let inputNode = audioEngine.inputNode
                let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, 
                                                  sampleRate: 16000, 
                                                  channels: 1, 
                                                  interleaved: false)!
                
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    guard let channelData = buffer.int16ChannelData?[0] else { return }
                    let data = Data(bytes: channelData, count: Int(buffer.frameLength) * 2)
                    continuation.yield(data)
                }
                
                audioEngine.prepare()
                try audioEngine.start()
                
                continuation.onTermination = { _ in
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                }
                
            } catch {
                continuation.finish()
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
