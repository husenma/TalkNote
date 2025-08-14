import Foundation

final class UserLearningStore {
    private(set) var currentPhrases: [String]

    init() {
        // Placeholder: load from persistence (UserDefaults/CoreData)
        self.currentPhrases = []
    }

    func addPhrase(_ phrase: String) {
        guard !phrase.isEmpty else { return }
        currentPhrases.append(phrase)
        // TODO: persist and sync to cloud custom model provider (e.g., Azure Custom Speech)
    }
}
