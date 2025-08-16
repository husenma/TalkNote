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
    let supportedTargets = ["en", "hi", "bn", "ta", "te", "mr", "gu", "kn", "ur", "es", "fr", "de", "zh-Hans", "ar", "ru", "ja", "ko"]
    let supportedSources = ["hi", "bn", "ta", "te", "mr", "gu", "kn", "ur", "en", "es", "fr", "de", "zh-Hans", "ar", "ru", "ja", "ko"]

    private lazy var audio = AudioEngine()
    private lazy var speech = SpeechService()
    private let translator = TranslatorService()
    private let learning = UserLearningStore()
    private let azureSpeech = AzureSpeechService()
    private let reinforcementLearning = ReinforcementLearningEngine()
    private var sessionStartTime: TimeInterval = 0

    func requestPermissions() {
        print("🔐 DEBUG: Requesting permissions...")
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print("🎤 DEBUG: iOS 17+ Audio permission granted: \(granted)")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("🎤 DEBUG: iOS 16- Audio permission granted: \(granted)")
            }
        }
        SpeechService.requestAuthorization()
        print("🗣️ DEBUG: Speech authorization requested")
    }

    func toggle() {
        print("🔄 DEBUG: Toggle called, current state: isTranscribing = \(isTranscribing)")
        if isTranscribing { stop() } else { start() }
    }

    func start() {
        print("🚀 DEBUG: Start function called")
        // Check permissions before starting
        let micPermissionGranted: Bool
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: micPermissionGranted = true
            default: micPermissionGranted = false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: micPermissionGranted = true
            default: micPermissionGranted = false
            }
        }
        
        let speechPermissionGranted = SFSpeechRecognizer.authorizationStatus() == .authorized
        print("🔐 DEBUG: Permissions - Mic: \(micPermissionGranted), Speech: \(speechPermissionGranted)")
        
        guard micPermissionGranted, speechPermissionGranted else {
            print("❌ DEBUG: Required permissions not granted - stopping start process")
            return
        }
        
        isTranscribing = true
        displayText = ""
        sessionStartTime = Date().timeIntervalSince1970
        print("🎤 DEBUG: Starting transcription...")

        // Prefer Azure Speech Translation with auto language detection when configured
        if azureSpeech.isAvailable {
            print("🔥 DEBUG: Using Azure Speech service")
            azureSpeech.start(targetLanguage: targetLanguage,
                              autoDetectLanguages: ["en-US","es-ES","fr-FR","de-DE","hi-IN","bn-IN","ta-IN","te-IN","mr-IN","gu-IN","kn-IN","ar-SA","ru-RU","ja-JP","ko-KR","zh-CN"],
                              phrases: learning.currentPhrases) { [weak self] text, isFinal, detectedLang in
                guard let self else { return }
                Task { @MainActor in
                    print("🎯 DEBUG: Azure speech result: '\(text)', isFinal: \(isFinal)")
                    if self.displayText.isEmpty { self.displayText = text } else { self.displayText += (text.isEmpty ? "" : " " + text) }
                    print("📝 DEBUG: displayText updated to: '\(self.displayText)'")
                }
                }
            }
            // No need to stream audio manually; Azure SDK handles mic capture via SPXAudioConfiguration
            return
        }

        // Fallback: Apple Speech + Azure Translator with RL enhancement
        print("🍎 DEBUG: Using Apple Speech service (Azure not available)")
        speech.start(onResult: { [weak self] text, isFinal, detectedLang in
            guard let self else { return }
            print("🎯 DEBUG: Apple speech result: '\(text)', isFinal: \(isFinal), detected: \(detectedLang)")
            Task { @MainActor in
                do {
                    let translated = try await self.translator.translate(text: text, from: detectedLang, to: self.targetLanguage)
                    print("🌐 DEBUG: Translation result: '\(translated)'")
                    
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
                        languageCode: detectedLang,
                        audioFeatures: audioFeatures,
                        userContext: userContext
                    )
                    print("🧠 DEBUG: RL optimized translation: '\(optimizedTranslation)'")
                    
                    if self.displayText.isEmpty {
                        self.displayText = optimizedTranslation
                    } else if isFinal {
                        self.displayText += (translated.hasSuffix(" ") ? translated : " " + translated)
                    } else {
                        // Show partial inline (optional). Keep UI simple: append preview with ellipsis
                        self.displayText += " " + translated
                    }
                    print("📝 DEBUG: Final displayText: '\(self.displayText)'")
                } catch {
                    // Ignore translation errors; keep raw text
                    print("❌ DEBUG: Translation error: \(error), using raw text: '\(text)'")
                    if self.displayText.isEmpty { self.displayText = text } else { self.displayText += " " + text }
                    print("📝 DEBUG: displayText (raw): '\(self.displayText)'")
                }
            }
        }, userPhrases: learning.currentPhrases)

        print("🎧 DEBUG: Starting audio streaming...")
        audio.startStreaming { [weak self] buffer, when in
            print("🔊 DEBUG: Audio buffer received, size: \(buffer.frameLength)")
            self?.speech.append(buffer: buffer)
        }
    }

    func stop() {
        print("⏹️ DEBUG: Stopping transcription...")
        isTranscribing = false
        audio.stop()
        Task { await speech.shutdown() }
        print("🔇 DEBUG: Transcription stopped, final text: '\(displayText)'")
    }    // MARK: - Reinforcement Learning Feedback
    
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
