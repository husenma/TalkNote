import Foundation
import AVFoundation

@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var displayText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var targetLanguage: String = "en"
    @Published var correctionMode: Bool = false
    @Published var learningStats: String = ""
    
    let supportedTargets = ["en", "es", "fr", "de", "zh-Hans", "hi", "bn", "ta", "te", "mr", "gu", "kn", "ar", "ru", "ja", "ko"]

    private let audio = AudioEngine()
    private let speech = SpeechService()
    private let translator = TranslatorService()
    private let learning = UserLearningStore()
    private let azureSpeech = AzureSpeechService()
    
    // 🧠 Reinforcement Learning Integration
    private let reinforcementLearning = ReinforcementLearningEngine()
    private var currentRecognizedText: String = ""
    private var currentLanguage: String = "en"
    private var lastConfidence: Float = 0.0

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
        isTranscribing = true
        displayText = ""

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

        // Fallback: Apple Speech + Azure Translator
        speech.start(onResult: { [weak self] text, isFinal, detectedLang in
            guard let self else { return }
            Task { @MainActor in
                do {
                    let translated = try await self.translator.translate(text: text, from: detectedLang, to: self.targetLanguage)
                    if self.displayText.isEmpty {
                        self.displayText = translated
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
                
                // 🧠 Record interaction for reinforcement learning
                self.recordLearningInteraction(recognizedText: text, isFinal: isFinal, detectedLanguage: detectedLang)
            }
    }, userPhrases: getEnhancedUserPhrases())

        audio.startStreaming { [weak self] buffer, when in
            self?.speech.append(buffer: buffer)
        }
    }

    func stop() {
        isTranscribing = false
        audio.stop()
        Task { await speech.shutdown() }
        updateLearningStats()
    }
    
    // MARK: - 🧠 Reinforcement Learning Methods
    
    private func getEnhancedUserPhrases() -> [String] {
        let personalizedPhrases = reinforcementLearning.getPersonalizedPhrases()
        let originalPhrases = learning.currentPhrases
        return Array(Set(personalizedPhrases + originalPhrases))
    }
    
    private func recordLearningInteraction(recognizedText: String, isFinal: Bool, detectedLanguage: String) {
        guard isFinal else { return }
        
        currentRecognizedText = recognizedText
        currentLanguage = detectedLanguage
        
        // Apply learned corrections
        let correctedText = reinforcementLearning.applyLearnedCorrections(to: recognizedText)
        if correctedText != recognizedText {
            displayText = correctedText
        }
        
        // Record interaction with neutral feedback (user can provide feedback later)
        reinforcementLearning.recordInteraction(
            userInput: "",
            recognizedText: recognizedText,
            correctedText: correctedText != recognizedText ? correctedText : nil,
            confidence: lastConfidence,
            language: detectedLanguage,
            feedback: .neutral
        )
    }
    
    /// User provides positive feedback on transcription accuracy
    func markAsCorrect() {
        guard !currentRecognizedText.isEmpty else { return }
        
        reinforcementLearning.recordInteraction(
            userInput: "",
            recognizedText: currentRecognizedText,
            correctedText: nil,
            confidence: lastConfidence,
            language: currentLanguage,
            feedback: .positive
        )
        updateLearningStats()
    }
    
    /// User provides negative feedback on transcription accuracy
    func markAsIncorrect() {
        guard !currentRecognizedText.isEmpty else { return }
        
        reinforcementLearning.recordInteraction(
            userInput: "",
            recognizedText: currentRecognizedText,
            correctedText: nil,
            confidence: lastConfidence,
            language: currentLanguage,
            feedback: .negative
        )
        updateLearningStats()
    }
    
    /// User provides correction for the transcribed text
    func provideCorrection(_ correctedText: String) {
        guard !currentRecognizedText.isEmpty else { return }
        
        reinforcementLearning.learnFromCorrection(
            original: currentRecognizedText,
            corrected: correctedText,
            language: currentLanguage
        )
        
        // Update display with corrected text
        displayText = correctedText
        updateLearningStats()
    }
    
    /// Toggle correction mode for user input
    func toggleCorrectionMode() {
        correctionMode.toggle()
    }
    
    /// Get learning analytics for display
    private func updateLearningStats() {
        let analytics = reinforcementLearning.getLearningAnalytics()
        let accuracy = String(format: "%.1f", (analytics["accuracy_score"] as? Double ?? 0) * 100)
        let interactions = analytics["total_interactions"] as? Int ?? 0
        learningStats = "Accuracy: \(accuracy)% | Interactions: \(interactions)"
    }
    
    /// Reset learning data (for privacy/debugging)
    func resetLearningData() {
        // This would clear all learning data
        updateLearningStats()
    }
}
