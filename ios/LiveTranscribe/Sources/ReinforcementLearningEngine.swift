import Foundation
import CoreML

/// Reinforcement Learning Engine for TalkNote
/// Learns from user interactions to improve speech recognition accuracy
final class ReinforcementLearningEngine: ObservableObject {
    
    // MARK: - Learning Data Storage
    private struct LearningData: Codable {
        let userInput: String
        let recognizedText: String
        let correctedText: String?
        let confidence: Float
        let timestamp: Date
        let language: String
        let userFeedback: FeedbackType
    }
    
    enum FeedbackType: String, Codable, CaseIterable {
        case positive = "correct"
        case negative = "incorrect" 
        case neutral = "no_feedback"
        case corrected = "user_corrected"
    }
    
    // MARK: - Properties
    @Published var learningProgress: Double = 0.0
    @Published var accuracyScore: Double = 0.75 // Starting accuracy
    @Published var totalInteractions: Int = 0
    
    private var learningHistory: [LearningData] = []
    private let maxHistorySize = 1000
    private let learningRate: Float = 0.01
    
    // MARK: - Initialization
    init() {
        loadLearningHistory()
        calculateCurrentAccuracy()
    }
    
    // MARK: - Public Methods
    
    /// Record user interaction for learning
    func recordInteraction(
        userInput: String,
        recognizedText: String,
        correctedText: String? = nil,
        confidence: Float,
        language: String,
        feedback: FeedbackType = .neutral
    ) {
        let interaction = LearningData(
            userInput: userInput,
            recognizedText: recognizedText,
            correctedText: correctedText,
            confidence: confidence,
            timestamp: Date(),
            language: language,
            userFeedback: feedback
        )
        
        addLearningData(interaction)
        updateAccuracyScore(interaction)
        adaptToUserPreferences()
        saveLearningHistory()
    }
    
    /// Get personalized phrases based on learning
    func getPersonalizedPhrases() -> [String] {
        let commonPhrases = learningHistory
            .compactMap { $0.correctedText ?? $0.recognizedText }
            .reduce(into: [String: Int]()) { counts, phrase in
                counts[phrase, default: 0] += 1
            }
            .sorted { $0.value > $1.value }
            .prefix(20)
            .map { $0.key }
        
        return Array(commonPhrases)
    }
    
    /// Get language preferences based on usage
    func getPreferredLanguages() -> [String] {
        let languageUsage = learningHistory
            .reduce(into: [String: Int]()) { counts, data in
                counts[data.language, default: 0] += 1
            }
            .sorted { $0.value > $1.value }
            .map { $0.key }
        
        return Array(languageUsage.prefix(5))
    }
    
    /// Get confidence boost for frequently used phrases
    func getConfidenceBoost(for text: String) -> Float {
        let similarPhrases = learningHistory.filter { data in
            let similarity = calculateSimilarity(text, data.recognizedText)
            return similarity > 0.8 && data.userFeedback == .positive
        }
        
        let boost = Float(similarPhrases.count) * 0.1
        return min(boost, 0.5) // Max 50% boost
    }
    
    /// Learn from user corrections
    func learnFromCorrection(original: String, corrected: String, language: String) {
        recordInteraction(
            userInput: "",
            recognizedText: original,
            correctedText: corrected,
            confidence: 0.5,
            language: language,
            feedback: .corrected
        )
        
        // Store common corrections for future reference
        addCommonCorrection(from: original, to: corrected)
    }
    
    // MARK: - Private Methods
    
    private func addLearningData(_ data: LearningData) {
        learningHistory.append(data)
        totalInteractions += 1
        
        // Maintain history size limit
        if learningHistory.count > maxHistorySize {
            learningHistory.removeFirst(learningHistory.count - maxHistorySize)
        }
        
        // Update learning progress
        learningProgress = min(Double(totalInteractions) / 1000.0, 1.0)
    }
    
    private func updateAccuracyScore(_ interaction: LearningData) {
        let feedback = interaction.userFeedback
        let confidenceWeight = interaction.confidence
        
        var scoreAdjustment: Double = 0.0
        
        switch feedback {
        case .positive:
            scoreAdjustment = Double(learningRate * confidenceWeight)
        case .negative:
            scoreAdjustment = -Double(learningRate * confidenceWeight)
        case .corrected:
            scoreAdjustment = -Double(learningRate * 0.5)
        case .neutral:
            scoreAdjustment = 0.0
        }
        
        accuracyScore = max(0.0, min(1.0, accuracyScore + scoreAdjustment))
    }
    
    private func calculateCurrentAccuracy() {
        let recentInteractions = learningHistory.suffix(100)
        guard !recentInteractions.isEmpty else { return }
        
        let positiveCount = recentInteractions.count { $0.userFeedback == .positive }
        let totalCount = recentInteractions.count
        
        accuracyScore = Double(positiveCount) / Double(totalCount)
    }
    
    private func adaptToUserPreferences() {
        // Analyze patterns in user corrections and feedback
        let recentCorrections = learningHistory
            .suffix(50)
            .filter { $0.userFeedback == .corrected }
        
        // Learn common error patterns
        for correction in recentCorrections {
            if let corrected = correction.correctedText {
                analyzeErrorPattern(
                    original: correction.recognizedText,
                    corrected: corrected
                )
            }
        }
    }
    
    private func analyzeErrorPattern(original: String, corrected: String) {
        // Simple pattern analysis - can be enhanced with ML models
        let originalWords = original.lowercased().components(separatedBy: .whitespaces)
        let correctedWords = corrected.lowercased().components(separatedBy: .whitespaces)
        
        // Store word substitution patterns
        if originalWords.count == correctedWords.count {
            for (index, originalWord) in originalWords.enumerated() {
                if originalWord != correctedWords[index] {
                    addWordSubstitution(from: originalWord, to: correctedWords[index])
                }
            }
        }
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Float {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespaces))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespaces))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Float(intersection.count) / Float(union.count)
    }
    
    // MARK: - Persistence
    
    private func saveLearningHistory() {
        guard let data = try? JSONEncoder().encode(learningHistory) else { return }
        UserDefaults.standard.set(data, forKey: "TalkNote_LearningHistory")
    }
    
    private func loadLearningHistory() {
        guard let data = UserDefaults.standard.data(forKey: "TalkNote_LearningHistory"),
              let history = try? JSONDecoder().decode([LearningData].self, from: data) else {
            return
        }
        learningHistory = history
        totalInteractions = history.count
    }
    
    // MARK: - Common Corrections & Word Substitutions
    
    private var commonCorrections: [String: String] = [:]
    private var wordSubstitutions: [String: String] = [:]
    
    private func addCommonCorrection(from original: String, to corrected: String) {
        commonCorrections[original.lowercased()] = corrected
        saveCommonCorrections()
    }
    
    private func addWordSubstitution(from original: String, to corrected: String) {
        wordSubstitutions[original.lowercased()] = corrected
        saveWordSubstitutions()
    }
    
    private func saveCommonCorrections() {
        UserDefaults.standard.set(commonCorrections, forKey: "TalkNote_CommonCorrections")
    }
    
    private func saveWordSubstitutions() {
        UserDefaults.standard.set(wordSubstitutions, forKey: "TalkNote_WordSubstitutions")
    }
    
    private func loadCommonCorrections() {
        commonCorrections = UserDefaults.standard.dictionary(forKey: "TalkNote_CommonCorrections") as? [String: String] ?? [:]
        wordSubstitutions = UserDefaults.standard.dictionary(forKey: "TalkNote_WordSubstitutions") as? [String: String] ?? [:]
    }
    
    /// Apply learned corrections to text
    func applyLearnedCorrections(to text: String) -> String {
        var correctedText = text
        
        // Apply common corrections
        for (original, correction) in commonCorrections {
            correctedText = correctedText.replacingOccurrences(
                of: original,
                with: correction,
                options: .caseInsensitive
            )
        }
        
        // Apply word substitutions
        let words = correctedText.components(separatedBy: .whitespaces)
        let correctedWords = words.map { word in
            wordSubstitutions[word.lowercased()] ?? word
        }
        
        return correctedWords.joined(separator: " ")
    }
    
    // MARK: - Analytics
    
    func getLearningAnalytics() -> [String: Any] {
        return [
            "total_interactions": totalInteractions,
            "accuracy_score": accuracyScore,
            "learning_progress": learningProgress,
            "preferred_languages": getPreferredLanguages(),
            "common_phrases_count": getPersonalizedPhrases().count,
            "corrections_learned": commonCorrections.count
        ]
    }
}
