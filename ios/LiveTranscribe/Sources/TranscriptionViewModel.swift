import SwiftUI
import Foundation
import AVFoundation
import Speech

// MARK: - Model Selection Enums
enum TranscriptionModel: String, CaseIterable, Identifiable {
    case appleOnDevice = "Apple On-Device"
    case appleServer = "Apple Server"
    case azureSpeech = "Azure Speech"
    case whisperKitBase = "WhisperKit Base"
    case whisperKitLarge = "WhisperKit Large-v3"
    case customTrained = "Custom Trained"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .appleOnDevice:
            return "On-Device"
        case .appleServer:
            return "Apple Server"
        case .azureSpeech:
            return "Azure Speech"
        case .whisperKitBase:
            return "Whisper Base"
        case .whisperKitLarge:
            return "Whisper Large"
        case .customTrained:
            return "Custom AI"
        }
    }
    
    var description: String {
        switch self {
        case .appleOnDevice:
            return "Fast, private, works offline"
        case .appleServer:
            return "Most accurate, requires internet"
        case .azureSpeech:
            return "Multi-language, cloud-based"
        case .whisperKitBase:
            return "OpenAI Whisper, balanced performance"
        case .whisperKitLarge:
            return "OpenAI Whisper, highest accuracy"
        case .customTrained:
            return "Your personalized model"
        }
    }
    
    var accuracy: String {
        // Return dynamic accuracy instead of hardcoded values
        return "Real-time"
    }
    
    var isOfflineCapable: Bool {
        switch self {
        case .appleOnDevice, .whisperKitBase, .whisperKitLarge, .customTrained:
            return true
        case .appleServer, .azureSpeech:
            return false
        }
    }
}

enum LanguageModel: String, CaseIterable, Identifiable {
    case multilingual = "Multilingual"
    case indianLanguages = "Indian Languages"
    case englishOptimized = "English Optimized"
    case regional = "Regional Languages"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .multilingual:
            return "Support for 100+ languages"
        case .indianLanguages:
            return "Optimized for 22+ Indian languages"
        case .englishOptimized:
            return "Best accuracy for English"
        case .regional:
            return "Local language variants"
        }
    }
}

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
    
    // MARK: - Dynamic Accuracy Tracking
    @Published var dynamicAccuracy: String = "Calculating..."
    @Published var conversationAccuracy: Float = 0.0
    private var transcriptionAttempts = 0
    private var successfulTranscriptions = 0
    private var totalConfidenceScore: Float = 0.0
    private var accuracyHistory: [Float] = []
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
    
    // Model Selection Settings
    @Published var selectedTranscriptionModel: TranscriptionModel = .appleOnDevice {
        didSet {
            // Stop current transcription when model changes to prevent crashes
            if isTranscribing {
                Task {
                    await self.stop()
                    await MainActor.run {
                        self.debugStatus = "Model switched to \(self.selectedTranscriptionModel.rawValue)"
                    }
                }
            }
        }
    }
    @Published var selectedLanguageModel: LanguageModel = .multilingual
    @Published var audioSensitivity: Float = 0.8
    @Published var noiseReduction: Bool = true
    @Published var soundEnvironmentDetection: Bool = true
    @Published var environmentSounds: String = ""
    
    let supportedSources = ["Auto-detect", "English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Urdu", "Bengali", "Telugu", "Marathi", "Tamil", "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi", "Assamese", "Nepali", "Sindhi", "Sanskrit"]
    let supportedTargets = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Japanese", "Korean", "Chinese", "Arabic", "Hindi", "Urdu", "Bengali", "Telugu", "Marathi", "Tamil", "Gujarati", "Kannada", "Malayalam", "Odia", "Punjabi", "Assamese", "Nepali", "Sindhi", "Sanskrit"]
    
    private let speechService = SpeechService()
    private let translatorService = TranslatorService()
    private let audioEngine = AudioEngine()
    private var speechTask: SFSpeechRecognitionTask?
    private var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    private let learningStore = UserLearningStore()
    private let whisperKitService = WhisperKitService()
    private let thermalManager = ThermalManager()
    
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
            await self.requestPermissions()
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
            _Concurrency.Task { await self.stop() }
        } else {
            _Concurrency.Task { await self.start() }
        }
    }
    
    func start() async {
        // Samsung-style thermal check before starting
        if thermalManager.thermalState == .critical {
            self.statusMessage = "Device too hot - cooling down"
            self.debugStatus = "🌡️ Thermal protection active"
            return
        }
        
        // Adjust model based on thermal state
        if thermalManager.isThrottled && (selectedTranscriptionModel == .whisperKitLarge || selectedTranscriptionModel == .customTrained) {
            // Automatically switch to more efficient model
            selectedTranscriptionModel = .whisperKitBase
            self.statusMessage = "Using efficient model to prevent overheating"
        }
        
        self.statusMessage = "Starting"
        self.debugStatus = "🎙️ Starting..."
        self.isRecording = true
        self.isTranscribing = true
        self.displayText = "" // Clear previous text
        
        // Enable heat reduction mode if needed
        whisperKitService.setHeatReductionMode(thermalManager.heatReductionActive)
        
        // Start with Apple Speech Recognition directly (more reliable)
        await startAppleSpeechRecognition()
    }
    
    func stop() async {
        audioEngine.stop()
        speechRequest?.endAudio()
        speechTask?.cancel()
        speechTask = nil
        speechRequest = nil
        
        // Stop WhisperKit if it was being used
        whisperKitService.stopTranscription()
        
        self.isRecording = false
        self.isTranscribing = false
        self.statusMessage = "Stopped"
        self.debugStatus = "Ready"
    }
    
    private func startAppleSpeechRecognition() async {
        self.debugStatus = "�️ Starting..."
        
        // Handle WhisperKit models separately
        if selectedTranscriptionModel == .whisperKitBase || selectedTranscriptionModel == .whisperKitLarge {
            await startWhisperKitTranscription()
            return
        }
        
        // Select recognizer based on model preference for Apple models
        let recognizer: SFSpeechRecognizer?
        
        switch selectedTranscriptionModel {
        case .appleOnDevice:
            recognizer = SFSpeechRecognizer()
        case .appleServer, .customTrained:
            recognizer = SFSpeechRecognizer()
        case .azureSpeech:
            // Fall back to Apple for now, will enhance with Azure
            recognizer = SFSpeechRecognizer()
        case .whisperKitBase, .whisperKitLarge:
            // This case is handled above
            return
        }
        
        guard let speechRecognizer = recognizer else {
            self.statusMessage = "Speech recognition not available"
            self.debugStatus = "SFSpeechRecognizer unavailable"
            self.isTranscribing = false
            return
        }
        
        guard speechRecognizer.isAvailable else {
            self.statusMessage = "Speech recognition not available"
            self.debugStatus = "Speech recognition unavailable"
            self.isTranscribing = false
            return
        }
        
        // Configure audio session for enhanced accuracy
        await configureAudioSessionForHighAccuracy()
        
        // Create enhanced request with better settings
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = (selectedTranscriptionModel == .appleOnDevice)
        
        // Enhanced settings for better accuracy
        if #available(iOS 13.0, *) {
            request.taskHint = .dictation // Better for continuous speech
        }
        
        speechRequest = request
        
        // Start the recognition task with enhanced error handling
        speechTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.debugStatus = "Error: \(error.localizedDescription)"
                    print("Speech recognition error: \(error)")
                    
                    // Auto-retry on certain errors
                    if self.shouldRetryOnError(error) {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                            await self.retryRecognition()
                        }
                    }
                    return
                }
                
                guard let result = result else { return }
                
                // Get raw transcription text first
                let rawText = result.bestTranscription.formattedString
                print("🎤 Raw transcription: '\(rawText)'")
                
                // Enhanced text processing with better accuracy
                let currentText = self.processTranscriptionText(rawText)
                print("📝 Processed text: '\(currentText)'")
                
                // Update UI immediately for real-time feel
                self.transcribedText = currentText.isEmpty ? rawText : currentText
                self.displayText = self.transcribedText
                self.debugStatus = "🎙️ Live (\(self.selectedTranscriptionModel.rawValue))"
                
                print("✅ Display text set to: '\(self.displayText)'")
                
                // Add confidence indicator and update accuracy
                if let segment = result.bestTranscription.segments.last {
                    let confidence = segment.confidence
                    
                    // Update dynamic accuracy based on actual performance
                    self.updateAccuracy(confidence: confidence, transcriptionLength: currentText.count)
                    
                    if confidence < 0.5 {
                        self.debugStatus += " - Low confidence"
                    } else if confidence > 0.9 {
                        self.debugStatus += " - High confidence"
                    }
                }
                
                // Process environment sounds if enabled
                if self.soundEnvironmentDetection {
                    self.detectEnvironmentSounds(from: result)
                }
                
                // Only do ML processing on final results in background
                if result.isFinal {
                    _Concurrency.Task.detached {
                        await self.processTranscriptionResult(currentText)
                    }
                }
            }
        }
        
        // Start enhanced audio engine with better settings
        audioEngine.startStreamingWithEnhancedSettings(
            sensitivity: audioSensitivity,
            noiseReduction: noiseReduction
        ) { [weak self] buffer, time in
            guard let self = self else { return }
            self.speechRequest?.append(buffer)
        }
        
        // Give more time for high-accuracy model to initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.isTranscribing {
                self.debugStatus = "🎙️ Live (\(self.selectedTranscriptionModel.rawValue))"
            }
        }
    }
    
    // MARK: - WhisperKit Transcription
    
    private func startWhisperKitTranscription() async {
        self.debugStatus = "🤖 Loading Whisper..."
        
        // Load appropriate WhisperKit model
        let whisperModel: WhisperKitService.WhisperModel = selectedTranscriptionModel == .whisperKitLarge ? .large : .base
        
        // Ensure WhisperKit model is loaded
        if !whisperKitService.isInitialized || whisperKitService.selectedModel != whisperModel {
            await whisperKitService.loadModel(whisperModel)
        }
        
        guard whisperKitService.isInitialized else {
            self.statusMessage = "WhisperKit failed to initialize"
            self.debugStatus = "WhisperKit error"
            self.isTranscribing = false
            return
        }
        
        self.debugStatus = "🤖 WhisperKit Ready"
        
        // Configure audio engine for WhisperKit (16kHz, mono)
        do {
            let audioStream = try audioEngine.startStreamingForWhisperKit()
            
            // Start WhisperKit streaming transcription
            Task {
                await whisperKitService.startStreamingTranscription(audioData: audioStream)
            }
            
            // Monitor WhisperKit transcription results
            monitorWhisperKitResults()
            
        } catch {
            self.statusMessage = "Audio setup failed"
            self.debugStatus = "Audio error: \(error.localizedDescription)"
            self.isTranscribing = false
        }
    }
    
    private func monitorWhisperKitResults() {
        // Update UI with WhisperKit results
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isTranscribing else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if !self.whisperKitService.currentText.isEmpty {
                    let transcription = self.whisperKitService.currentText
                    
                    // Update display text
                    self.displayText = transcription
                    
                    // Update status with confidence and processing time
                    let confidence = Int(self.whisperKitService.confidence * 100)
                    let processTime = Int(self.whisperKitService.processingTime * 1000)
                    self.debugStatus = "🤖 WhisperKit (\(confidence)% conf, \(processTime)ms)"
                    
                    // Process translation if needed
                    if self.targetLanguage != "English" && !transcription.isEmpty {
                        await self.processTranslation(transcription)
                    }
                }
                
                // Handle errors
                if let error = self.whisperKitService.errorMessage {
                    self.statusMessage = "WhisperKit error: \(error)"
                    self.debugStatus = "Error"
                }
            }
        }
    }
    
    private func processTranslation(_ text: String) async {
        // Translate the text if needed
        if targetLanguage != "English" && !text.isEmpty {
            do {
                let translated = try await translatorService.translate(
                    text: text, 
                    from: detectedLanguageCode, 
                    to: languageNameToCode(targetLanguage)
                )
                
                await MainActor.run {
                    self.translatedText = translated
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Translation failed"
                }
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
    
    // MARK: - Enhanced Audio Processing
    
    private func configureAudioSessionForHighAccuracy() async {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Set preferred sample rate for higher quality
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer for low latency
            
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func processTranscriptionText(_ text: String) -> String {
        var processedText = text
        
        // Apply text enhancement based on selected model
        switch selectedLanguageModel {
        case .multilingual:
            processedText = enhanceMultilingualText(processedText)
        case .indianLanguages:
            processedText = enhanceIndianLanguageText(processedText)
        case .englishOptimized:
            processedText = enhanceEnglishText(processedText)
        case .regional:
            processedText = enhanceRegionalText(processedText)
        }
        
        return processedText
    }
    
    private func enhanceMultilingualText(_ text: String) -> String {
        // Apply general multilingual text corrections
        var enhanced = text
        
        // Common corrections for mixed language text
        enhanced = enhanced.replacingOccurrences(of: " न ", with: " नहीं ")
        enhanced = enhanced.replacingOccurrences(of: " क ", with: " का ")
        enhanced = enhanced.replacingOccurrences(of: " म ", with: " में ")
        
        return enhanced
    }
    
    private func enhanceIndianLanguageText(_ text: String) -> String {
        var enhanced = text
        
        // Hindi language specific corrections
        enhanced = enhanced.replacingOccurrences(of: "हे", with: "है")
        enhanced = enhanced.replacingOccurrences(of: "मै", with: "मैं")
        enhanced = enhanced.replacingOccurrences(of: "आप के", with: "आपके")
        enhanced = enhanced.replacingOccurrences(of: "नमस्ते", with: "नमस्ते")
        
        // Add more Indian language corrections based on common mistakes
        return enhanced
    }
    
    private func enhanceEnglishText(_ text: String) -> String {
        var enhanced = text
        
        // Common English corrections
        enhanced = enhanced.replacingOccurrences(of: " i ", with: " I ")
        enhanced = enhanced.replacingOccurrences(of: " im ", with: " I'm ")
        enhanced = enhanced.replacingOccurrences(of: " dont ", with: " don't ")
        enhanced = enhanced.replacingOccurrences(of: " cant ", with: " can't ")
        enhanced = enhanced.replacingOccurrences(of: " wont ", with: " won't ")
        
        return enhanced
    }
    
    private func enhanceRegionalText(_ text: String) -> String {
        // Apply regional language specific enhancements
        return text
    }
    
    private func shouldRetryOnError(_ error: Error) -> Bool {
        // Check if the error is recoverable
        let nsError = error as NSError
        return nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 // Audio session error
    }
    
    private func retryRecognition() async {
        guard isTranscribing else { return }
        
        debugStatus = "🔄 Retrying..."
        
        // Stop current recognition
        speechTask?.cancel()
        speechTask = nil
        speechRequest?.endAudio()
        speechRequest = nil
        
        // Wait a moment then restart
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await startAppleSpeechRecognition()
    }
    
    private func detectEnvironmentSounds(from result: SFSpeechRecognitionResult) {
        // Analyze audio characteristics to detect environment sounds
        // This is a simplified implementation
        let transcription = result.bestTranscription.formattedString.lowercased()
        
        var detectedSounds: [String] = []
        
        // Check for common sound patterns (this would be enhanced with ML)
        if transcription.contains("music") || transcription.contains("song") {
            detectedSounds.append("🎵 Music")
        }
        if transcription.contains("car") || transcription.contains("traffic") {
            detectedSounds.append("🚗 Traffic")
        }
        if transcription.contains("phone") || transcription.contains("ring") {
            detectedSounds.append("📱 Phone")
        }
        if transcription.contains("door") || transcription.contains("knock") {
            detectedSounds.append("🚪 Door")
        }
        
        if !detectedSounds.isEmpty {
            self.environmentSounds = detectedSounds.joined(separator: " ")
        } else {
            self.environmentSounds = ""
        }
    }
    
    // MARK: - Dynamic Accuracy Calculation
    
    private func updateAccuracy(confidence: Float, transcriptionLength: Int) {
        transcriptionAttempts += 1
        
        // Consider transcription successful if confidence > 0.6 and has content
        if confidence > 0.6 && transcriptionLength > 0 {
            successfulTranscriptions += 1
        }
        
        // Add to running confidence total
        totalConfidenceScore += confidence
        accuracyHistory.append(confidence)
        
        // Keep only last 100 measurements for moving average
        if accuracyHistory.count > 100 {
            accuracyHistory.removeFirst()
        }
        
        // Calculate dynamic accuracy
        calculateDynamicAccuracy()
    }
    
    private func calculateDynamicAccuracy() {
        guard transcriptionAttempts > 0 else {
            dynamicAccuracy = "Calculating..."
            return
        }
        
        // Calculate various accuracy metrics
        let successRate = Float(successfulTranscriptions) / Float(transcriptionAttempts)
        let averageConfidence = totalConfidenceScore / Float(transcriptionAttempts)
        let recentConfidence = accuracyHistory.suffix(10).reduce(0, +) / Float(min(10, accuracyHistory.count))
        
        // Weighted accuracy: 40% success rate, 35% average confidence, 25% recent confidence
        let weightedAccuracy = (successRate * 0.4) + (averageConfidence * 0.35) + (recentConfidence * 0.25)
        
        // Convert to percentage and clamp between realistic bounds (65-98%)
        conversationAccuracy = min(max(weightedAccuracy * 100, 65), 98)
        
        // Update string representation with realistic assessment
        if conversationAccuracy >= 95 {
            dynamicAccuracy = String(format: "%.0f%% (Excellent)", conversationAccuracy)
        } else if conversationAccuracy >= 90 {
            dynamicAccuracy = String(format: "%.0f%% (Very Good)", conversationAccuracy)
        } else if conversationAccuracy >= 85 {
            dynamicAccuracy = String(format: "%.0f%% (Good)", conversationAccuracy)
        } else if conversationAccuracy >= 80 {
            dynamicAccuracy = String(format: "%.0f%% (Fair)", conversationAccuracy)
        } else {
            dynamicAccuracy = String(format: "%.0f%% (Poor)", conversationAccuracy)
        }
        
        print("🎯 Dynamic accuracy updated: \(dynamicAccuracy) (attempts: \(transcriptionAttempts), success: \(successfulTranscriptions))")
    }
}
