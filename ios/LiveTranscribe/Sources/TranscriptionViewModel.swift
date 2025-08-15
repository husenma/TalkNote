import Foundation
import AVFoundation

@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var displayText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var targetLanguage: String = "en"
    let supportedTargets = ["en", "es", "fr", "de", "zh-Hans", "hi", "bn", "ta", "te", "mr", "gu", "kn", "ar", "ru", "ja", "ko"]

    private let audio = AudioEngine()
    private let speech = SpeechService()
    private let translator = TranslatorService()
    private let learning = UserLearningStore()
    private let azureSpeech = AzureSpeechService()

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
}
