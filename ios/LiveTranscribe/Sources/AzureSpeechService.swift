import Foundation

#if canImport(MicrosoftCognitiveServicesSpeech)
import MicrosoftCognitiveServicesSpeech

final class AzureSpeechService {
    private var recognizer: SPXTranslationRecognizer?
    private var refreshTimer: Timer?
    private var region: String = ""
    private var target: String = "en"

    var isAvailable: Bool { SpeechAuthProvider.shared.isConfigured }

    func start(targetLanguage: String,
               autoDetectLanguages: [String],
               phrases: [String] = [],
               onResult: @escaping (_ text: String, _ isFinal: Bool, _ detectedLang: String) -> Void) {
        Task {
            do {
                self.target = targetLanguage

                let (token, region) = try await SpeechAuthProvider.shared.fetchToken()
                self.region = region

                let config = try SPXSpeechTranslationConfiguration(authorizationToken: token, region: region)
                try config.addTargetLanguage(targetLanguage)

                let autoCfg = try SPXAutoDetectSourceLanguageConfiguration(languages: autoDetectLanguages)
                let audioCfg = SPXAudioConfiguration()
                let rec = try SPXTranslationRecognizer(speechTranslationConfiguration: config,
                                                       autoDetectSourceLanguageConfiguration: autoCfg,
                                                       audioConfiguration: audioCfg)

                // Phrase list grammar to bias recognition
                if !phrases.isEmpty {
                    let pl = try SPXPhraseListGrammar(recognizer: rec)
                    for p in phrases { try? pl.addPhrase(p) }
                }

                rec.addRecognizingEventHandler { _, evt in
                    guard let res = evt?.result else { return }
                    let text = res.translations?[self.target] as? String ?? res.text ?? ""
                    let lang = (res.properties?[.speechServiceConnectionAutoDetectSourceLanguageResult] as? String) ?? "auto"
                    onResult(text, false, lang)
                }

                rec.addRecognizedEventHandler { _, evt in
                    guard let res = evt?.result else { return }
                    let text = res.translations?[self.target] as? String ?? res.text ?? ""
                    let lang = (res.properties?[.speechServiceConnectionAutoDetectSourceLanguageResult] as? String) ?? "auto"
                    onResult(text, true, lang)
                }

                self.recognizer = rec
                try rec.startContinuousRecognition()

                // Refresh auth token ~9 minutes (tokens expire ~10 min)
                self.scheduleTokenRefresh()
            } catch {
                // Surface a minimal error via callback so UI can fallback
                onResult("", true, "auto")
            }
        }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        if let rec = recognizer {
            try? rec.stopContinuousRecognition()
        }
        recognizer = nil
    }

    private func scheduleTokenRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 9 * 60, repeats: true) { [weak self] _ in
            guard let self, let rec = self.recognizer else { return }
            Task {
                if let (token, _) = try? await SpeechAuthProvider.shared.fetchToken() {
                    // Update token on the configuration owning the recognizer
                    rec.authorizationToken = token
                }
            }
        }
    }
}

#else

final class AzureSpeechService {
    var isAvailable: Bool { false }
    func start(targetLanguage: String, autoDetectLanguages: [String], phrases: [String] = [], onResult: @escaping (_ text: String, _ isFinal: Bool, _ detectedLang: String) -> Void) {
        onResult("", true, "auto")
    }
    func stop() {}
}

#endif
