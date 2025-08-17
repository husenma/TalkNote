import SwiftUI
import Foundation
import AVFoundation
import Speech

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var transcribedText = ""
    @Published var translatedText = ""
    @Published var detectedLanguage = "Unknown"
    @Published var detectedLanguageCode = "auto"
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
    
    // UI Control Settings
    @Published var isMLLearningEnabled = true
    @Published var isAutoDetectEnabled = true
    @Published var confidenceThreshold: Double = 0.8
    
    let supportedSources = ["Auto-detect", "English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Urdu", "Bengali", "Telugu", "Marathi", "Tamil", "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi", "Assamese", "Nepali", "Sindhi", "Sanskrit"]
    let supportedTargets = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Urdu", "Bengali", "Telugu", "Marathi", "Tamil", "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi", "Assamese", "Nepali", "Sindhi", "Sanskrit"]
    
    private let speechService = SpeechService()
    private let translatorService = TranslatorService()
    private let audioEngine = AudioEngine()
    private var speechTask: SFSpeechRecognitionTask?
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private let learningStore = UserLearningStore()
    
    // ML and Reinforcement Learning
    private let indianLanguageML = IndianLanguageMLModel()
    private let enhancedRL: EnhancedReinforcementLearningEngine
    private var currentTranscriptionContext: TranscriptionContext
    private var sessionStartTime = Date()
    
    init() {
        // Initialize transcription context
        let calendar = Calendar.current
        let now = Date()
        sessionStartTime = now
        currentTranscriptionContext = TranscriptionContext(
            timeOfDay: calendar.component(.hour, from: now),
            dayOfWeek: calendar.component(.weekday, from: now),
            previousLanguage: nil,
            sessionLength: 0,
            backgroundNoise: .moderate
        )
        
        // Initialize enhanced reinforcement learning
        enhancedRL = EnhancedReinforcementLearningEngine(
            mlModel: indianLanguageML
        )
        
        // Request permissions on initialization
        _Concurrency.Task {
            await requestPermissions()
        }
    }
    
    func requestPermissions() async {
        // Request microphone permission
        let micStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        if micStatus && speechStatus == .authorized {
            self.statusMessage = "Permissions granted"
            self.debugStatus = "Ready for transcription"
        } else {
            self.statusMessage = "Permissions required"
            self.debugStatus = "Need microphone and speech permissions"
        }
    }
    
    var allPermissionsGranted: Bool {
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        let speechPermission = SFSpeechRecognizer.authorizationStatus()
        return micPermission == .granted && speechPermission == .authorized
    }
    
    func toggle() {
        if isTranscribing {
            _Concurrency.Task { await stop() }
        } else {
            _Concurrency.Task { await start() }
        }
    }
    
    func start() async {
        self.statusMessage = "Starting"
        self.debugStatus = "🎙️ Starting..."
        self.isRecording = true
        self.isTranscribing = true
        self.displayText = "" // Clear previous text
        
        // Start with Apple Speech Recognition directly (more reliable)
        await startAppleSpeechRecognition()
    }
    
    func stop() async {
        audioEngine.stop()
        speechRequest?.endAudio()
        speechTask?.cancel()
        speechTask = nil
        speechRequest = nil
        
        self.isRecording = false
        self.isTranscribing = false
        self.statusMessage = "Stopped"
        self.debugStatus = "Ready"
    }
    
    private func startAppleSpeechRecognition() async {
        self.debugStatus = "🍎 Connecting..."
        
        guard let recognizer = SFSpeechRecognizer() else {
            self.statusMessage = "Speech recognition not available"
            self.debugStatus = "SFSpeechRecognizer unavailable"
            self.isTranscribing = false
            return
        }
        
        guard recognizer.isAvailable else {
            self.statusMessage = "Speech recognition not available"
            self.debugStatus = "Speech recognition unavailable"
            self.isTranscribing = false
            return
        }
        
        // Create new request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        speechRequest = request
        
        // Start the recognition task
        speechTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.debugStatus = "Error occurred"
                    print("Speech recognition error: \(error)")
                    return
                }
                
                guard let result = result else { return }
                
                // IMMEDIATE real-time display - no processing delays
                let currentText = result.bestTranscription.formattedString
                self.transcribedText = currentText
                self.displayText = currentText
                self.debugStatus = "🎙️ Live"
                
                // Only do ML processing on final results in background
                if result.isFinal {
                    _Concurrency.Task.detached {
                        await self.processTranscriptionResult(currentText)
                    }
                }
            }
        }
        
        // Now start the audio engine after the speech task is set up
        audioEngine.startStreaming { [weak self] buffer, time in
            guard let self = self else { return }
            // Feed audio directly to speech recognition
            self.speechRequest?.append(buffer)
        }
        
        // Give a moment for audio engine to start, then update status
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.isTranscribing {
                self.debugStatus = "🎙️ Live"
            }
        }
    }
    
    private func processTranscriptionResult(_ result: String) async {
        // Skip ML processing if disabled
        guard isMLLearningEnabled else {
            await MainActor.run {
                self.displayText = result
            }
            return
        }
        
        // Background ML processing - don't update displayText to avoid overriding real-time updates
        
        // Enhanced ML language detection (in background) - only if auto-detect is enabled
        if isAutoDetectEnabled {
            let enhancedPrediction = await enhancedRL.getPredictedLanguageWithRL(
                for: result,
                context: currentTranscriptionContext
            )
            
            // Apply confidence threshold
            if enhancedPrediction.confidence >= Float(confidenceThreshold) {
                await MainActor.run {
                    // Only update language detection results, not the displayed text
                    self.detectedLanguage = enhancedPrediction.language
                    self.detectedLanguageCode = self.languageNameToCode(enhancedPrediction.language)
                    self.predictionReasoning = enhancedPrediction.reasoning
                    // Keep showing live status, don't override with AI processing status
                }
                
                // Translate if not English (in background) and confidence is high enough
                if enhancedPrediction.language != "en" {
                    await translateText(result)
                }
            } else {
                // Low confidence - use default language or skip translation
                await MainActor.run {
                    self.predictionReasoning = "Low confidence (\(Int(enhancedPrediction.confidence * 100))%) - using default language"
                }
            }
        }
        
        // Store for learning (in background) - only if ML learning is enabled
        learningStore.addPhrase(result)
        
        // Store for reinforcement learning (in background)
        await storeForReinforcementLearning(
            originalText: result,
            detectedLanguage: detectedLanguage,
            translatedText: translatedText
        )
    }
    
    private func translateText(_ text: String) async {
        // Background translation - don't show translation status in debug
        do {
            let translated = try await translatorService.translate(text: text, from: detectedLanguageCode, to: "en")
            await MainActor.run {
                self.translatedText = translated
                // Don't override debug status with translation status
            }
        } catch {
            await MainActor.run {
                self.translatedText = "Translation failed"
            }
        }
    }
    
    private func storeForReinforcementLearning(
        originalText: String,
        detectedLanguage: String,
        translatedText: String
    ) async {
        // Store interaction data for RL learning
        await enhancedRL.recordUserCorrection(
            originalText: originalText,
            detectedLanguage: detectedLanguage,
            correctLanguage: detectedLanguage,
            confidence: 0.8,
            context: currentTranscriptionContext
        )
        
        // Update context for next prediction
        currentTranscriptionContext = TranscriptionContext(
            timeOfDay: Calendar.current.component(.hour, from: Date()),
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            previousLanguage: detectedLanguage,
            sessionLength: Date().timeIntervalSince(sessionStartTime),
            backgroundNoise: .moderate
        )
    }
    
    private func languageNameToCode(_ languageName: String) -> String {
        switch languageName.lowercased() {
        case "english": return "en"
        case "hindi": return "hi"
        case "bengali": return "bn"
        case "tamil": return "ta"
        case "telugu": return "te"
        case "marathi": return "mr"
        case "gujarati": return "gu"
        case "kannada": return "kn"
        case "malayalam": return "ml"
        case "odia": return "or"
        case "punjabi": return "pa"
        case "assamese": return "as"
        case "nepali": return "ne"
        case "sindhi": return "sd"
        case "sanskrit": return "sa"
        case "urdu": return "ur"
        case "spanish": return "es"
        case "french": return "fr"
        case "german": return "de"
        case "italian": return "it"
        case "portuguese": return "pt"
        case "russian": return "ru"
        case "japanese": return "ja"
        case "korean": return "ko"
        case "chinese": return "zh"
        case "arabic": return "ar"
        default: return "auto"
        }
    }
    
    func testTranscription() {
        self.isTranscribing = true
        self.isRecording = true
        self.debugStatus = "🎙️ Live (Test Mode)"
        self.transcribedText = "नमस्ते, मैं हिंदी बोल रहा हूँ"
        self.displayText = "नमस्ते, मैं हिंदी बोल रहा हूँ"
        self.detectedLanguage = "Hindi"
        self.detectedLanguageCode = "hi"
        self.translatedText = "Hello, I am speaking Hindi"
        self.statusMessage = "Test completed"
    }
    
    func clearText() {
        self.transcribedText = ""
        self.translatedText = ""
        self.displayText = ""
        self.statusMessage = "Cleared"
        self.debugStatus = "Text cleared"
    }
    
    func forceStart() {
        self.isRecording = true
        self.isTranscribing = true
        self.statusMessage = "Force started"
        self.debugStatus = "Force start initiated"
        self.transcribedText = "Force start activated - microphone should be active"
        self.displayText = "Force start activated - microphone should be active"
        
        // Try to force start the audio engine
        audioEngine.startStreaming { [weak self] buffer, time in
            guard let self = self else { return }
            // Process audio buffer
            self.speechRequest?.append(buffer)
        }
        
        self.debugStatus = "Force start: Audio engine activated"
    }
    
    // MARK: - User Feedback for Reinforcement Learning
    func correctLanguageDetection(correctLanguage: String) {
        _Concurrency.Task {
            guard !transcribedText.isEmpty else { return }
            
            await enhancedRL.recordUserCorrection(
                originalText: transcribedText,
                detectedLanguage: detectedLanguage,
                correctLanguage: correctLanguage,
                confidence: 0.8,
                context: currentTranscriptionContext
            )
            
            await MainActor.run {
                self.detectedLanguage = correctLanguage
                self.detectedLanguageCode = self.languageNameToCode(correctLanguage)
                self.learningProgress = enhancedRL.learningProgress
                self.statusMessage = "Thank you for the correction!"
                
                // Update context for next prediction
                self.currentTranscriptionContext = TranscriptionContext(
                    timeOfDay: Calendar.current.component(.hour, from: Date()),
                    dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                    previousLanguage: correctLanguage,
                    sessionLength: Date().timeIntervalSince(self.sessionStartTime),
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
        _Concurrency.Task {
            await MainActor.run {
                self.learningProgress = 0.0
                self.statusMessage = "Learning data reset"
            }
        }
    }
    
    func checkPermissionsStatus() {
        // Check microphone permission
        let micPermission = AVAudioSession.sharedInstance().recordPermission
        
        // Check speech recognition permission
        let speechPermission = SFSpeechRecognizer.authorizationStatus()
        
        let micStatus = micPermission == .granted ? "✅ Granted" : "❌ Denied"
        let speechStatus = speechPermission == .authorized ? "✅ Authorized" : "❌ Not Authorized"
        
        self.debugStatus = "Mic: \(micStatus) | Speech: \(speechStatus)"
        self.displayText = "Permission Status:\n• Microphone: \(micStatus)\n• Speech Recognition: \(speechStatus)"
    }
}
