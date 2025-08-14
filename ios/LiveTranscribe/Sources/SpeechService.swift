import Foundation
import AVFoundation
import Speech

final class SpeechService {
    private let recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    init(locale: Locale = Locale(identifier: "en-US")) {
        // Start with a default; we will still try to detect language via NLLanguageRecognizer heuristics
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    static func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    func start(onResult: @escaping (_ text: String, _ isFinal: Bool, _ detectedLanguage: String) -> Void,
               userPhrases: [String] = []) {
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        // Phrase hints aren't directly supported by SFSpeechRecognizer; use custom language model in Azure for production
        // Here we just start the task
        task = recognizer?.recognitionTask(with: request!) { result, error in
            guard let result = result else { return }
            let text = result.bestTranscription.formattedString

            // Heuristic language detection for UI hinting; for production, rely on Azure Speech identifyLanguage
            let detected = SpeechService.detectLanguage(for: text) ?? (self.recognizer?.locale.identifier ?? "en-US")

            onResult(text, result.isFinal, detected)

            if result.isFinal || error != nil {
                self.task?.cancel()
                self.task = nil
            }
        }
    }

    func append(buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    func shutdown() async {
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
    }

    private static func detectLanguage(for text: String) -> String? {
        guard !text.isEmpty else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }
}
