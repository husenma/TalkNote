import Foundation

final class UserLearningStore: ObservableObject {
    @Published private(set) var currentPhrases: [String]
    @Published var totalPhrasesLearned: Int = 0
    
    private let maxPhrases = 500
    private let userDefaultsKey = "TalkNote_UserPhrases"

    init() {
        self.currentPhrases = Self.loadPhrasesFromStorage()
        self.totalPhrasesLearned = currentPhrases.count
    }

    func addPhrase(_ phrase: String) {
        guard !phrase.isEmpty, !currentPhrases.contains(phrase) else { return }
        
        currentPhrases.append(phrase)
        totalPhrasesLearned += 1
        
        // Maintain phrase limit
        if currentPhrases.count > maxPhrases {
            currentPhrases.removeFirst(currentPhrases.count - maxPhrases)
        }
        
        savePhrases()
        
        // TODO: sync to cloud custom model provider (e.g., Azure Custom Speech)
    }
    
    func addPhrases(_ phrases: [String]) {
        for phrase in phrases {
            addPhrase(phrase)
        }
    }
    
    func removePhrase(_ phrase: String) {
        currentPhrases.removeAll { $0 == phrase }
        savePhrases()
    }
    
    func clearAllPhrases() {
        currentPhrases.removeAll()
        totalPhrasesLearned = 0
        savePhrases()
    }
    
    func getTopPhrases(limit: Int = 50) -> [String] {
        return Array(currentPhrases.suffix(limit))
    }
    
    // MARK: - Persistence
    
    private func savePhrases() {
        UserDefaults.standard.set(currentPhrases, forKey: userDefaultsKey)
    }
    
    private static func loadPhrasesFromStorage() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "TalkNote_UserPhrases") ?? []
    }
}
