import Foundation
import Combine
import Speech
import AVFoundation

// Type aliases to avoid conflicts
public typealias RLUserContext = UserContext
public typealias RLAudioFeatures = AudioFeatures

/// Reinforcement Learning Engine for Indian Languages to English Translation
/// Optimizes translation quality through user feedback and contextual learning
public class ReinforcementLearningEngine: ObservableObject {
    
    // MARK: - Types
    
    public struct TranslationAction {
        let sourceText: String
        let translatedText: String
        let confidence: Float
        let languageCode: String
        let audioFeatures: RLAudioFeatures
        let timestamp: Date
    }
    
    public struct LearningState {
        let recentTranslations: [TranslationAction]
        let userContext: RLUserContext
        let environmentalFactors: EnvironmentalFactors
    }
    
    public struct EnvironmentalFactors {
        let noiseLevel: Float
        let acousticEnvironment: AcousticEnvironment
        let timeOfDay: TimeOfDay
    }
    
    public enum AgeGroup {
        case child, young, adult, senior
    }
    
    public enum AcousticEnvironment {
        case quiet, moderate, noisy, outdoor
    }
    
    public enum TimeOfDay {
        case morning, afternoon, evening, night
    }
    
    public struct Reward {
        let value: Float // -1.0 to 1.0
        let feedback: FeedbackType
        let context: String?
    }
    
    public enum FeedbackType {
        case userCorrection
        case userApproval
        case implicitPositive // user didn't correct
        case implicitNegative // user immediately re-spoke
        case contextualClues // based on follow-up conversation
    }
    
    // MARK: - Properties
    
    @Published public var learningMetrics = LearningMetrics()
    @Published public var isTraining = false
    
    private var qTable: [String: Float] = [:]
    private var experienceBuffer: [Experience] = []
    private let maxBufferSize = 10000
    private var episodeCount = 0
    
    // Hyperparameters
    private let learningRate: Float = 0.1
    private let discountFactor: Float = 0.95
    private let explorationRate: Float = 0.1
    private let explorationDecay: Float = 0.995
    private var currentExplorationRate: Float
    
    // Indian Language Specific Models
    private var hindiModel: LanguageSpecificModel
    private var tamilModel: LanguageSpecificModel
    private var teluguModel: LanguageSpecificModel
    private var bengaliModel: LanguageSpecificModel
    private var marathiModel: LanguageSpecificModel
    private var gujaratiModel: LanguageSpecificModel
    
    private let userDefaults = UserDefaults.standard
    private let modelPersistenceKey = "RLTranslationModel"
    
    public struct LearningMetrics {
        var totalTranslations: Int = 0
        var averageReward: Float = 0.0
        var accuracyTrend: [Float] = []
        var languageSpecificAccuracy: [String: Float] = [:]
        var improvementRate: Float = 0.0
    }
    
    private struct Experience {
        let state: LearningState
        let action: TranslationAction
        let reward: Float
        let nextState: LearningState?
        let timestamp: Date
    }
    
    // MARK: - Initialization
    
    public init() {
        self.currentExplorationRate = explorationRate
        
        // Initialize language-specific models
        self.hindiModel = LanguageSpecificModel(language: "hi")
        self.tamilModel = LanguageSpecificModel(language: "ta")
        self.teluguModel = LanguageSpecificModel(language: "te")
        self.bengaliModel = LanguageSpecificModel(language: "bn")
        self.marathiModel = LanguageSpecificModel(language: "mr")
        self.gujaratiModel = LanguageSpecificModel(language: "gu")
        
        loadPersistedModel()
    }
    
    // MARK: - Public Interface
    
    /// Optimizes translation based on current state and returns improved translation
    public func optimizeTranslation(
        originalText: String,
        proposedTranslation: String,
        confidence: Float,
        languageCode: String,
        audioFeatures: RLAudioFeatures,
        userContext: RLUserContext
    ) -> String {
        
        let currentState = createLearningState(
            userContext: userContext,
            audioFeatures: audioFeatures
        )
        
        let action = TranslationAction(
            sourceText: originalText,
            translatedText: proposedTranslation,
            confidence: confidence,
            languageCode: languageCode,
            audioFeatures: audioFeatures,
            timestamp: Date()
        )
        
        // Get Q-value for current state-action pair
        let stateActionKey = createStateActionKey(state: currentState, action: action)
        let qValue = qTable[stateActionKey] ?? 0.0
        
        // Apply language-specific optimizations
        let optimizedTranslation = applyLanguageSpecificOptimization(
            action: action,
            state: currentState,
            qValue: qValue
        )
        
        // Store experience for later learning
        let optimizedAction = TranslationAction(
            sourceText: originalText,
            translatedText: optimizedTranslation,
            confidence: confidence,
            languageCode: languageCode,
            audioFeatures: audioFeatures,
            timestamp: Date()
        )
        
        storeExperience(state: currentState, action: optimizedAction)
        
        return optimizedTranslation
    }
    
    /// Processes user feedback to improve future translations
    public func processFeedback(
        originalAction: TranslationAction,
        feedback: Reward,
        correctedTranslation: String? = nil
    ) {
        
        updateExperienceWithReward(action: originalAction, reward: feedback)
        
        if let correction = correctedTranslation {
            learnFromCorrection(
                original: originalAction,
                correction: correction,
                reward: feedback
            )
        }
        
        // Update language-specific model
        updateLanguageSpecificModel(
            languageCode: originalAction.languageCode,
            action: originalAction,
            reward: feedback.value
        )
        
        // Trigger learning update
        performQLearningUpdate()
        updateMetrics()
    }
    
    /// Trains the model on accumulated experiences
    public func trainModel() {
        guard !experienceBuffer.isEmpty else { return }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.performBatchTraining()
        }
    }
    
    // MARK: - Private Methods
    
    private func createLearningState(
        userContext: RLUserContext,
        audioFeatures: RLAudioFeatures
    ) -> LearningState {
        
        let environmentalFactors = EnvironmentalFactors(
            noiseLevel: Float(audioFeatures.noiseLevel),
            acousticEnvironment: classifyAcousticEnvironment(audioFeatures),
            timeOfDay: getCurrentTimeOfDay()
        )
        
        let recentTranslations = getRecentTranslations(limit: 5)
        
        return LearningState(
            recentTranslations: recentTranslations,
            userContext: userContext,
            environmentalFactors: environmentalFactors
        )
    }
    
    private func applyLanguageSpecificOptimization(
        action: TranslationAction,
        state: LearningState,
        qValue: Float
    ) -> String {
        
        let model = getLanguageModel(for: action.languageCode)
        return model.optimizeTranslation(
            text: action.translatedText,
            confidence: action.confidence,
            qValue: qValue,
            context: state.userContext
        )
    }
    
    private func getLanguageModel(for languageCode: String) -> LanguageSpecificModel {
        switch languageCode {
        case "hi": return hindiModel
        case "ta": return tamilModel
        case "te": return teluguModel
        case "bn": return bengaliModel
        case "mr": return marathiModel
        case "gu": return gujaratiModel
        default: return hindiModel // fallback
        }
    }
    
    private func performQLearningUpdate() {
        guard let lastExperience = experienceBuffer.last else { return }
        
        let stateActionKey = createStateActionKey(
            state: lastExperience.state,
            action: lastExperience.action
        )
        
        let currentQ = qTable[stateActionKey] ?? 0.0
        let maxNextQ = getMaxQValue(for: lastExperience.nextState)
        
        let newQ = currentQ + learningRate * (
            lastExperience.reward + discountFactor * maxNextQ - currentQ
        )
        
        qTable[stateActionKey] = newQ
        
        // Decay exploration rate
        currentExplorationRate *= explorationDecay
        currentExplorationRate = max(currentExplorationRate, 0.01)
    }
    
    private func createStateActionKey(state: LearningState, action: TranslationAction) -> String {
        let stateHash = hashState(state)
        let actionHash = hashAction(action)
        return "\(stateHash)_\(actionHash)"
    }
    
    private func hashState(_ state: LearningState) -> String {
        // Create a simplified hash of the state for Q-table indexing
        let contextHash = state.userContext.languagePreference
        let noiseLevel = Int(state.environmentalFactors.noiseLevel * 10)
        let timeOfDay = state.environmentalFactors.timeOfDay
        
        return "\(contextHash)_\(noiseLevel)_\(timeOfDay)"
    }
    
    private func hashAction(_ action: TranslationAction) -> String {
        // Create a simplified hash of the action
        let confidenceLevel = Int(action.confidence * 10)
        let textLength = min(action.translatedText.count / 10, 10)
        
        return "\(action.languageCode)_\(confidenceLevel)_\(textLength)"
    }
    
    private func getMaxQValue(for state: LearningState?) -> Float {
        guard let state = state else { return 0.0 }
        
        let stateHash = hashState(state)
        let relevantQValues = qTable.filter { $0.key.hasPrefix(stateHash) }
        
        return relevantQValues.values.max() ?? 0.0
    }
    
    private func storeExperience(state: LearningState, action: TranslationAction) {
        let experience = Experience(
            state: state,
            action: action,
            reward: 0.0, // Will be updated when feedback is received
            nextState: nil,
            timestamp: Date()
        )
        
        experienceBuffer.append(experience)
        
        if experienceBuffer.count > maxBufferSize {
            experienceBuffer.removeFirst()
        }
    }
    
    private func updateExperienceWithReward(action: TranslationAction, reward: Reward) {
        // Find and update the corresponding experience
        for i in experienceBuffer.indices.reversed() {
            if experienceBuffer[i].action.timestamp == action.timestamp {
                experienceBuffer[i] = Experience(
                    state: experienceBuffer[i].state,
                    action: experienceBuffer[i].action,
                    reward: reward.value,
                    nextState: experienceBuffer[i].nextState,
                    timestamp: experienceBuffer[i].timestamp
                )
                break
            }
        }
    }
    
    private func learnFromCorrection(
        original: TranslationAction,
        correction: String,
        reward: Reward
    ) {
        // Store the correction as a high-value example
        let correctedAction = TranslationAction(
            sourceText: original.sourceText,
            translatedText: correction,
            confidence: 1.0, // High confidence for human corrections
            languageCode: original.languageCode,
            audioFeatures: original.audioFeatures,
            timestamp: Date()
        )
        
        // Store the corrected action in experience buffer for learning
        let currentState = createLearningState(
            userContext: RLUserContext(), // Default context for corrections
            audioFeatures: original.audioFeatures
        )
        storeExperience(state: currentState, action: correctedAction)
        
        // Add to language-specific model training data
        let model = getLanguageModel(for: original.languageCode)
        model.addTrainingExample(
            source: original.sourceText,
            target: correction,
            weight: abs(reward.value) + 0.5
        )
    }
    
    private func updateLanguageSpecificModel(
        languageCode: String,
        action: TranslationAction,
        reward: Float
    ) {
        let model = getLanguageModel(for: languageCode)
        model.updateWithFeedback(
            translation: action.translatedText,
            reward: reward,
            context: action.audioFeatures
        )
    }
    
    private func performBatchTraining() {
        isTraining = true
        
        // Sample experiences for training
        let batchSize = min(32, experienceBuffer.count)
        let experiences = Array(experienceBuffer.suffix(batchSize))
        
        for experience in experiences {
            let stateActionKey = createStateActionKey(
                state: experience.state,
                action: experience.action
            )
            
            let currentQ = qTable[stateActionKey] ?? 0.0
            let maxNextQ = getMaxQValue(for: experience.nextState)
            
            let targetQ = experience.reward + discountFactor * maxNextQ
            let newQ = currentQ + learningRate * (targetQ - currentQ)
            
            qTable[stateActionKey] = newQ
        }
        
        episodeCount += 1
        
        DispatchQueue.main.async { [weak self] in
            self?.isTraining = false
            self?.persistModel()
        }
    }
    
    private func updateMetrics() {
        learningMetrics.totalTranslations += 1
        
        // Calculate average reward from recent experiences
        let recentExperiences = experienceBuffer.suffix(100)
        let avgReward = recentExperiences.map { $0.reward }.reduce(0, +) / Float(recentExperiences.count)
        learningMetrics.averageReward = avgReward
        
        // Update accuracy trend
        learningMetrics.accuracyTrend.append(avgReward)
        if learningMetrics.accuracyTrend.count > 100 {
            learningMetrics.accuracyTrend.removeFirst()
        }
        
        // Calculate improvement rate
        if learningMetrics.accuracyTrend.count >= 10 {
            let recent = learningMetrics.accuracyTrend.suffix(10).reduce(0, +) / 10
            let older = learningMetrics.accuracyTrend.prefix(10).reduce(0, +) / 10
            learningMetrics.improvementRate = recent - older
        }
    }
    
    // MARK: - Utility Methods
    
    internal func classifyAcousticEnvironment(_ features: RLAudioFeatures) -> AcousticEnvironment {
        switch features.noiseLevel {
        case 0.0..<0.2: return .quiet
        case 0.2..<0.5: return .moderate
        case 0.5..<0.8: return .noisy
        default: return .outdoor
        }
    }
    
    private func getCurrentTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
    
    private func getRecentTranslations(limit: Int) -> [TranslationAction] {
        return Array(experienceBuffer.suffix(limit).map { $0.action })
    }
    
    // MARK: - Persistence
    
    private func persistModel() {
        let modelData = [
            "qTable": qTable,
            "episodeCount": episodeCount,
            "explorationRate": currentExplorationRate
        ] as [String: Any]
        
        if let data = try? JSONSerialization.data(withJSONObject: modelData) {
            userDefaults.set(data, forKey: modelPersistenceKey)
        }
    }
    
    private func loadPersistedModel() {
        guard let data = userDefaults.data(forKey: modelPersistenceKey),
              let modelData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let qTableData = modelData["qTable"] as? [String: Float] {
            qTable = qTableData
        }
        
        if let episode = modelData["episodeCount"] as? Int {
            episodeCount = episode
        }
        
        if let exploration = modelData["explorationRate"] as? Float {
            currentExplorationRate = exploration
        }
    }
}

// MARK: - Language Specific Model

private class LanguageSpecificModel {
    let languageCode: String
    private var phrasePatterns: [String: Float] = [:]
    private var contextualMappings: [String: String] = [:]
    private var trainingExamples: [(source: String, target: String, weight: Float)] = []
    
    init(language: String) {
        self.languageCode = language
        loadLanguageSpecificPatterns()
    }
    
    func optimizeTranslation(
        text: String,
        confidence: Float,
        qValue: Float,
        context: RLUserContext
    ) -> String {
        // Apply language-specific optimizations
        var optimizedText = text
        
        // Apply contextual mappings
        for (pattern, replacement) in contextualMappings {
            optimizedText = optimizedText.replacingOccurrences(of: pattern, with: replacement)
        }
        
        // Apply confidence-based adjustments
        if confidence < 0.5 && qValue > 0.0 {
            optimizedText = improveWithPatternMatching(optimizedText)
        }
        
        return optimizedText
    }
    
    func addTrainingExample(source: String, target: String, weight: Float) {
        trainingExamples.append((source: source, target: target, weight: weight))
        
        // Keep only recent examples
        if trainingExamples.count > 1000 {
            trainingExamples.removeFirst()
        }
    }
    
    func updateWithFeedback(translation: String, reward: Float, context: RLAudioFeatures) {
        // Update phrase patterns based on feedback
        let words = translation.components(separatedBy: .whitespaces)
        for word in words {
            let currentScore = phrasePatterns[word] ?? 0.0
            phrasePatterns[word] = currentScore + (reward * 0.1)
        }
    }
    
    private func loadLanguageSpecificPatterns() {
        // Load common patterns and corrections for each Indian language
        switch languageCode {
        case "hi":
            contextualMappings = [
                "namaste": "hello",
                "dhanyawad": "thank you",
                "kaise hain": "how are you"
            ]
        case "ta":
            contextualMappings = [
                "vanakkam": "hello",
                "nandri": "thank you",
                "eppadi irukinga": "how are you"
            ]
        case "te":
            contextualMappings = [
                "namaskaram": "hello",
                "dhanyavadalu": "thank you",
                "ela unnaru": "how are you"
            ]
        // Add more languages...
        default:
            break
        }
    }
    
    private func improveWithPatternMatching(_ text: String) -> String {
        // Use stored patterns to improve translation
        var improvedText = text
        let words = text.components(separatedBy: .whitespaces)
        
        for i in words.indices {
            let word = words[i]
            if let betterTranslation = findBetterTranslation(for: word) {
                improvedText = improvedText.replacingOccurrences(of: word, with: betterTranslation)
            }
        }
        
        return improvedText
    }
    
    private func findBetterTranslation(for word: String) -> String? {
        // Look for better translations in training examples
        for example in trainingExamples.reversed() {
            if example.source.contains(word) && example.weight > 0.5 {
                // Extract potential better translation
                // This is simplified - in practice, you'd use more sophisticated NLP
                return nil // Placeholder
            }
        }
        return nil
    }
}
