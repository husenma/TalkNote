import SwiftUI
import AVFoundation
import Speech

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcribedText = ""
    @Published var translatedText = ""
    @Published var detectedLanguage = "Unknown"
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var isAutoPaused = false
    @Published var autoResumeTimer: Timer?
    @Published var statusMessage = "Ready"
    @Published var debugStatus = "Initializing..."
    @Published var displayText = ""
    @Published var sourceLanguage = "Auto-detect"
    @Published var targetLanguage = "English"
    @Published var mlModelStatus = "Initializing ML models..."
    @Published var learningProgress: Float = 0.0
    @Published var predictionReasoning = ""
    
    let supportedSources = ["Auto-detect", "English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Urdu", "Bengali", "Telugu", "Marathi", "Tamil", "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi", "Assamese", "Nepali", "Sindhi", "Sanskrit"]
    let supportedTargets = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Urdu", "Bengali", "Telugu", "Marathi", "Tamil", "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi", "Assamese", "Nepali", "Sindhi", "Sanskrit"]
    
    private let speechService = SpeechService()
    private let translatorService = TranslatorService()
    private let audioEngine = AudioEngine()
    private var speechTask: SFSpeechRecognitionTask?
    private let learningStore = UserLearningStore()
    
    // ML and Reinforcement Learning
    private let indianLanguageML = IndianLanguageMLModel()
    private let enhancedRL: EnhancedReinforcementLearningEngine
    private var currentTranscriptionContext: TranscriptionContext
    
    init() {
        // Initialize transcription context
        let calendar = Calendar.current
        let now = Date()
        currentTranscriptionContext = TranscriptionContext(
            timeOfDay: calendar.component(.hour, from: now),
            dayOfWeek: calendar.component(.weekday, from: now),
            previousLanguage: nil,
            sessionLength: 0,
            backgroundNoise: .moderate
        )
        
        // Initialize enhanced reinforcement learning
        enhancedRL = EnhancedReinforcementLearningEngine(mlModel: indianLanguageML)
        
        Task {
            await requestPermissions()
            await initializeMLModels()
        }
    }
    
    private func requestPermissions() async {
        // Request microphone permission
        let micStatus = await AVAudioSession.sharedInstance().requestRecordPermission()
        
        // Request speech recognition permission
        let speechStatus = await SFSpeechRecognizer.requestAuthorization()
        
        if micStatus && speechStatus == .authorized {
            await MainActor.run {
                self.statusMessage = "Permissions granted"
                self.debugStatus = "Ready for transcription"
            }
        } else {
            await MainActor.run {
                self.statusMessage = "Permissions required"
                self.debugStatus = "Need microphone and speech permissions"
            }
        }
    }
    
    private func initializeMLModels() async {
        await MainActor.run {
            self.mlModelStatus = "Downloading Indian language models..."
        }
        
        // Wait for ML models to initialize
        while !indianLanguageML.isInitialized {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        await MainActor.run {
            self.mlModelStatus = "ML models ready"
            self.statusMessage = "Ready with AI enhancement"
        }
    }
    
    func toggle() {
        Task {
            if isTranscribing {
                await stop()
            } else {
                await start()
            }
        }
    }
    
    func start() async {
        await MainActor.run {
            self.statusMessage = "Starting transcription..."
            self.debugStatus = "Initializing audio engine..."
            self.isRecording = true
            self.isTranscribing = true
        }
        
        do {
            try await audioEngine.startRecording()
            
            await MainActor.run {
                self.statusMessage = "Recording..."
                self.debugStatus = "Audio engine started successfully"
            }
            
            // Try Azure Speech Service first
            await startAzureSpeechService()
            
        } catch {
            // Fall back to Apple Speech Recognition
            await startAppleSpeechRecognition()
        }
    }
    
    func stop() async {
        await audioEngine.stopRecording()
        speechTask?.cancel()
        
        await MainActor.run {
            self.isRecording = false
            self.isTranscribing = false
            self.statusMessage = "Stopped"
            self.debugStatus = "Transcription stopped"
        }
    }
    
    private func startAzureSpeechService() async {
        await MainActor.run {
            self.debugStatus = "Trying Azure Speech Service..."
        }
        
        do {
            let result = try await speechService.startContinuousRecognition()
            await processTranscriptionResult(result)
        } catch {
            await MainActor.run {
                self.debugStatus = "Azure failed, using Apple Speech..."
            }
            await startAppleSpeechRecognition()
        }
    }
    
    private func startAppleSpeechRecognition() async {
        await MainActor.run {
            self.debugStatus = "Using Apple Speech Recognition..."
        }
        
        guard let recognizer = SFSpeechRecognizer() else {
            await MainActor.run {
                self.statusMessage = "Speech recognition not available"
                self.debugStatus = "SFSpeechRecognizer unavailable"
            }
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        do {
            speechTask = try await recognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    Task { @MainActor in
                        self.transcribedText = result.bestTranscription.formattedString
                        self.displayText = result.bestTranscription.formattedString
                        self.debugStatus = "Transcribing: \(result.bestTranscription.formattedString.prefix(30))..."
                        
                        if result.isFinal {
                            await self.translateText(result.bestTranscription.formattedString)
                        }
                    }
                }
                
                if let error = error {
                    Task { @MainActor in
                        self.statusMessage = "Recognition error"
                        self.debugStatus = "Speech recognition error"
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.statusMessage = "Failed to start recognition"
                self.debugStatus = "Failed to start Apple Speech"
            }
        }
    }
    
    private func processTranscriptionResult(_ result: String) async {
        await MainActor.run {
            self.transcribedText = result
            self.displayText = result
            self.debugStatus = "Processing: \(result.prefix(30))..."
        }
        
        // Enhanced ML language detection
        let enhancedPrediction = await enhancedRL.getPredictedLanguageWithRL(
            for: result,
            context: currentTranscriptionContext
        )
        
        await MainActor.run {
            self.detectedLanguage = enhancedPrediction.language
            self.predictionReasoning = enhancedPrediction.reasoning
        }
        
        // Translate if not English
        if enhancedPrediction.language != "en" {
            await translateText(result)
        }
        
        // Store for reinforcement learning
        await learningStore.recordInteraction(
            originalText: result,
            detectedLanguage: enhancedPrediction.language,
            translatedText: translatedText
        )
    }
    
    private func translateText(_ text: String) async {
        await MainActor.run {
            self.debugStatus = "Translating text..."
        }
        
        do {
            let translated = try await translatorService.translate(text: text, to: "en")
            await MainActor.run {
                self.translatedText = translated
                self.debugStatus = "Translation complete"
            }
        } catch {
            await MainActor.run {
                self.translatedText = "Translation failed"
                self.debugStatus = "Translation error"
            }
        }
    }
    
    private func detectLanguageHeuristically(text: String) -> String {
        let supportedLanguages = ["en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh", "ar", "hi", "ur", "bn", "te", "mr", "ta", "gu", "kn", "ml", "or", "pa", "as", "ne", "sd", "sa"]
        
        // Indian Languages Character Detection
        // Hindi (Devanagari script)
        if text.range(of: "[\\u0900-\\u097F]", options: .regularExpression) != nil {
            return "hi"
        }
        
        // Bengali (Bengali script)
        if text.range(of: "[\\u0980-\\u09FF]", options: .regularExpression) != nil {
            return "bn"
        }
        
        // Telugu (Telugu script)
        if text.range(of: "[\\u0C00-\\u0C7F]", options: .regularExpression) != nil {
            return "te"
        }
        
        // Marathi (Devanagari script - same as Hindi but context-based)
        if text.range(of: "[\\u0900-\\u097F]", options: .regularExpression) != nil {
            // Additional Marathi-specific patterns could be added here
            return "mr"
        }
        
        // Tamil (Tamil script)
        if text.range(of: "[\\u0B80-\\u0BFF]", options: .regularExpression) != nil {
            return "ta"
        }
        
        // Gujarati (Gujarati script)
        if text.range(of: "[\\u0A80-\\u0AFF]", options: .regularExpression) != nil {
            return "gu"
        }
        
        // Kannada (Kannada script)
        if text.range(of: "[\\u0C80-\\u0CFF]", options: .regularExpression) != nil {
            return "kn"
        }
        
        // Malayalam (Malayalam script)
        if text.range(of: "[\\u0D00-\\u0D7F]", options: .regularExpression) != nil {
            return "ml"
        }
        
        // Odia/Oriya (Odia script)
        if text.range(of: "[\\u0B00-\\u0B7F]", options: .regularExpression) != nil {
            return "or"
        }
        
        // Punjabi (Gurmukhi script)
        if text.range(of: "[\\u0A00-\\u0A7F]", options: .regularExpression) != nil {
            return "pa"
        }
        
        // Assamese (Bengali script - similar to Bengali)
        if text.range(of: "[\\u0980-\\u09FF]", options: .regularExpression) != nil {
            return "as"
        }
        
        // Urdu (Arabic script with additional characters)
        if text.range(of: "[\\u0600-\\u06FF\\u0750-\\u077F\\u08A0-\\u08FF\\uFB50-\\uFDFF\\uFE70-\\uFEFF]", options: .regularExpression) != nil {
            return "ur"
        }
        
        // Sanskrit (Devanagari script)
        if text.range(of: "[\\u0900-\\u097F]", options: .regularExpression) != nil {
            return "sa"
        }
        
        // Nepali (Devanagari script)
        if text.range(of: "[\\u0900-\\u097F]", options: .regularExpression) != nil {
            return "ne"
        }
        
        // Sindhi (Arabic script variant)
        if text.range(of: "[\\u0600-\\u06FF]", options: .regularExpression) != nil {
            return "sd"
        }
        
        // Other Major Languages
        // Arabic
        if text.range(of: "[\\u0600-\\u06FF]", options: .regularExpression) != nil {
            return "ar"
        }
        
        // Hebrew
        if text.range(of: "[\\u0590-\\u05FF]", options: .regularExpression) != nil {
            return "he"
        }
        
        // Chinese (Han characters)
        if text.range(of: "[\\u4E00-\\u9FFF]", options: .regularExpression) != nil {
            return "zh"
        }
        
        // Japanese (Hiragana, Katakana)
        if text.range(of: "[\\u3040-\\u309F\\u30A0-\\u30FF]", options: .regularExpression) != nil {
            return "ja"
        }
        
        // Korean (Hangul)
        if text.range(of: "[\\uAC00-\\uD7FF]", options: .regularExpression) != nil {
            return "ko"
        }
        
        // Russian (Cyrillic)
        if text.range(of: "[\\u0400-\\u04FF]", options: .regularExpression) != nil {
            return "ru"
        }
        
        // Default to English if no specific patterns found
        return "en"
    }
    
    func testTranscription() {
        Task {
            await MainActor.run {
                self.transcribedText = "नमस्ते, मैं हिंदी बोल रहा हूँ"
                self.translatedText = "Hello, I am speaking Hindi"
                self.displayText = "नमस्ते, मैं हिंदी बोल रहा हूँ"
                self.detectedLanguage = "Hindi"
                self.statusMessage = "Test completed"
                self.debugStatus = "Hindi test transcription displayed"
            }
        }
    }
    
    func clearText() {
        Task {
            await MainActor.run {
                self.transcribedText = ""
                self.translatedText = ""
                self.displayText = ""
                self.statusMessage = "Cleared"
                self.debugStatus = "Text cleared"
            }
        }
    }
    
    func forceStart() {
        Task {
            await MainActor.run {
                self.isRecording = true
                self.isTranscribing = true
                self.statusMessage = "Force started"
                self.debugStatus = "Force start initiated"
                self.transcribedText = "Force start activated - microphone should be active"
                self.displayText = "Force start activated - microphone should be active"
            }
            
            // Try to force start the audio engine
            do {
                try await audioEngine.startRecording()
                await MainActor.run {
                    self.debugStatus = "Force start: Audio engine activated"
                }
            } catch {
                await MainActor.run {
                    self.debugStatus = "Force start: Audio engine failed"
                }
            }
        }
    }
    
    // MARK: - User Feedback for Reinforcement Learning
    func correctLanguageDetection(correctLanguage: String) {
        Task {
            guard !transcribedText.isEmpty else { return }
            
            await enhancedRL.recordUserCorrection(
                originalText: transcribedText,
                detectedLanguage: detectedLanguage,
                correctLanguage: correctLanguage,
                confidence: 0.8, // Placeholder confidence
                context: currentTranscriptionContext
            )
            
            await MainActor.run {
                self.detectedLanguage = correctLanguage
                self.learningProgress = enhancedRL.learningProgress
                self.statusMessage = "Thank you for the correction!"
                
                // Update context for next prediction
                self.currentTranscriptionContext = TranscriptionContext(
                    timeOfDay: Calendar.current.component(.hour, from: Date()),
                    dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                    previousLanguage: correctLanguage,
                    sessionLength: Date().timeIntervalSince(Date()), // Simplified
                    backgroundNoise: .moderate
                )
            }
        }
    }
    
    func getLearningStats() -> LearningStats {
        return enhancedRL.getLearningStats()
    }
    
    func resetLearning() {
        enhancedRL.resetLearning()
        Task {
            await MainActor.run {
                self.learningProgress = 0.0
                self.statusMessage = "Learning data reset"
            }
        }
    }
}

// MARK: - ReinforcementLearningEngine
class ReinforcementLearningEngine {
    func updateModel(originalText: String, detectedLanguage: String, translatedText: String) {
        // Placeholder for reinforcement learning implementation
        // This would analyze user corrections and improve detection accuracy
    }
    
    func getPredictedLanguage(for text: String) -> String {
        // Placeholder for ML-based language prediction
        // This would use trained model to predict language
        return "en"
    }
}
