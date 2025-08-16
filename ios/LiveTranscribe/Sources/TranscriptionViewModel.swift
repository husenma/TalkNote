import Foundation
import AVFoundation
import Speech

@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var displayText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var targetLanguage: String = "en"
    @Published var sourceLanguage: String = "hi" // Default to Hindi for Indian users
    
    // Enhanced language support with Indian languages
    let supportedTargets = ["en", "hi", "bn", "ta", "te", "mr", "gu", "kn", "es", "fr", "de", "zh-Hans", "ar", "ru", "ja", "ko"]
    let supportedSources = ["hi", "bn", "ta", "te", "mr", "gu", "kn", "en", "es", "fr", "de", "zh-Hans", "ar", "ru", "ja", "ko"]

    private lazy var audio = AudioEngine()
    private lazy var speech = SpeechService()
    private let translator = TranslatorService()
    private let learning = UserLearningStore()
    private let azureSpeech = AzureSpeechService()
    private let reinforcementLearning = ReinforcementLearningEngine()
    private var sessionStartTime: TimeInterval = 0

    func requestPermissions() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { _ in }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        }
        SpeechService.requestAuthorization()
    }

    func toggle() {
        if isTranscribing { stop() } else { start() }
    }

    func start() {
        // Check permissions before starting
        let micPermissionGranted: Bool
        if #available(iOS 17.0, *) {
            micPermissionGranted = AVAudioApplication.shared.recordPermission == .granted
        } else {
            micPermissionGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        
        guard micPermissionGranted,
              SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("Required permissions not granted")
            return
        }
        
        isTranscribing = true
        displayText = ""
        sessionStartTime = Date().timeIntervalSince1970

        // Prefer Azure Speech Translation with auto language detection when configured
        if azureSpeech.isAvailable {
            azureSpeech.start(targetLanguage: targetLanguage,
                              autoDetectLanguages: ["en-US","es-ES","fr-FR","de-DE","hi-IN","bn-IN","ta-IN","te-IN","mr-IN","gu-IN","kn-IN","ar-SA","ru-RU","ja-JP","ko-KR","zh-CN"],
                              phrases: learning.currentPhrases) { [weak self] text, isFinal, detectedLang in
                guard let self else { return }
                Task { @MainActor in
                    if self.displayText.isEmpty { self.displayText = text } else { self.displayText += (text.isEmpty ? "" : " " + text) }
                }
            }
            // No need to stream audio manually; Azure SDK handles mic capture via SPXAudioConfiguration
            return
        }

        // Fallback: Apple Speech + Azure Translator with RL enhancement
        speech.start(onResult: { [weak self] text, isFinal, detectedLang in
            guard let self else { return }
            Task { @MainActor in
                do {
                    let translated = try await self.translator.translate(text: text, from: detectedLang, to: self.targetLanguage)
                    
                    // Enhance translation with reinforcement learning
                    let audioFeatures = RLAudioFeatures()
                    let userContext = RLUserContext(
                        languagePreference: self.sourceLanguage,
                        sessionDuration: Date().timeIntervalSince1970 - self.sessionStartTime
                    )
                    
                    let optimizedTranslation = self.reinforcementLearning.optimizeTranslation(
                        originalText: text,
                        proposedTranslation: translated,
                        confidence: 0.8, // Default confidence from Azure
                        languageCode: detectedLang ?? self.sourceLanguage,
                        audioFeatures: audioFeatures,
                        userContext: userContext
                    )
                    
                    if self.displayText.isEmpty {
                        self.displayText = optimizedTranslation
                    } else if isFinal {
                        self.displayText += (translated.hasSuffix(" ") ? translated : " " + translated)
                    } else {
                        // Show partial inline (optional). Keep UI simple: append preview with ellipsis
                        self.displayText += " " + translated
                    }
                } catch {
                    // Ignore translation errors; keep raw text
                    if self.displayText.isEmpty { self.displayText = text } else { self.displayText += " " + text }
                }
            }
    }, userPhrases: learning.currentPhrases)

        audio.startStreaming { [weak self] buffer, when in
            self?.speech.append(buffer: buffer)
        }
    }

    func stop() {
        isTranscribing = false
        audio.stop()
        Task { await speech.shutdown() }
    }
    
    // MARK: - Reinforcement Learning Feedback
    
    func provideFeedback(isPositive: Bool, correctedText: String? = nil) {
        guard !displayText.isEmpty else { return }
        
        let reward = ReinforcementLearningEngine.Reward(
            value: isPositive ? 1.0 : -1.0,
            feedback: correctedText != nil ? .userCorrection : (isPositive ? .userApproval : .implicitNegative),
            context: "User feedback on translation"
        )
        
        // Create a translation action for the current text
        let translationAction = ReinforcementLearningEngine.TranslationAction(
            sourceText: displayText, // Simplified - in production, track original
            translatedText: displayText,
            confidence: 0.8,
            languageCode: sourceLanguage,
            audioFeatures: RLAudioFeatures(),
            timestamp: Date()
        )
        
        reinforcementLearning.processFeedback(
            originalAction: translationAction,
            feedback: reward,
            correctedTranslation: correctedText
        )
    }
    
    func clearText() {
        displayText = ""
    }
    
    func shareText() {
        // Share functionality - can be implemented later
    }
}
