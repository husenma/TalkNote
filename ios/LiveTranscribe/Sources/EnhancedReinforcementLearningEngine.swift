import Foundation
import CoreML
import Combine

@MainActor
class EnhancedReinforcementLearningEngine: ObservableObject {
    
    // MARK: - User Feedback & Learning
    @Published var learningProgress: Float = 0.0
    @Published var correctionsCount = 0
    @Published var accuracyImprovement: Float = 0.0
    
    // MARK: - Learning Data Storage
    private var userCorrections: [UserCorrection] = []
    private var languagePatterns: [String: LanguagePattern] = [:]
    private var contextualLearning: [ContextualPattern] = []
    private var adaptiveWeights: [String: Float] = [:]
    
    // MARK: - Model References
    private let indianLanguageML: IndianLanguageMLModel
    private var personalizedModel: MLModel?
    
    // MARK: - Learning Configuration
    private let maxCorrections = 1000
    private let learningRate: Float = 0.01
    private let retrainingThreshold = 50
    
    init(mlModel: IndianLanguageMLModel) {
        self.indianLanguageML = mlModel
        loadExistingLearningData()
        initializeAdaptiveWeights()
    }
    
    // MARK: - User Correction Learning
    func recordUserCorrection(
        originalText: String,
        detectedLanguage: String,
        correctLanguage: String,
        confidence: Float,
        context: TranscriptionContext
    ) async {
        let correction = UserCorrection(
            originalText: originalText,
            detectedLanguage: detectedLanguage,
            correctLanguage: correctLanguage,
            originalConfidence: confidence,
            timestamp: Date(),
            context: context,
            textLength: originalText.count,
            wordCount: originalText.components(separatedBy: .whitespacesAndNewlines).count
        )
        
        userCorrections.append(correction)
        correctionsCount += 1
        
        // Update language patterns
        await updateLanguagePatterns(from: correction)
        
        // Update contextual learning
        await updateContextualPatterns(from: correction)
        
        // Adjust adaptive weights
        await adjustAdaptiveWeights(from: correction)
        
        // Check if retraining is needed
        if correctionsCount % retrainingThreshold == 0 {
            await retrainPersonalizedModel()
        }
        
        await updateLearningProgress()
        
        // Save learning data
        saveLearningData()
    }
    
    // MARK: - Enhanced Language Prediction
    func getPredictedLanguageWithRL(for text: String, context: TranscriptionContext) async -> EnhancedPrediction {
        // Get base ML prediction
        let mlResult = await indianLanguageML.detectLanguageWithML(text: text)
        
        // Apply reinforcement learning adjustments
        let rlAdjustedScores = await applyReinforcementLearning(
            baseScores: mlResult.allScores,
            text: text,
            context: context
        )
        
        // Apply contextual learning
        let contextualAdjustment = await applyContextualLearning(
            scores: rlAdjustedScores,
            context: context
        )
        
        // Apply pattern matching from user corrections
        let patternAdjustment = await applyPatternMatching(
            scores: contextualAdjustment,
            text: text
        )
        
        // Find best prediction
        let sortedScores = patternAdjustment.sorted { $0.value > $1.value }
        let predictedLanguage = sortedScores.first?.key ?? "hi"
        let finalConfidence = sortedScores.first?.value ?? 0.5
        
        return EnhancedPrediction(
            language: predictedLanguage,
            confidence: finalConfidence,
            baseMLConfidence: mlResult.confidence,
            rlAdjustment: calculateRLAdjustment(base: mlResult.confidence, final: finalConfidence),
            allScores: patternAdjustment,
            reasoning: generatePredictionReasoning(
                baseML: mlResult,
                rlAdjusted: rlAdjustedScores,
                contextual: contextualAdjustment,
                pattern: patternAdjustment
            )
        )
    }
    
    // MARK: - Reinforcement Learning Application
    private func applyReinforcementLearning(
        baseScores: [String: Float],
        text: String,
        context: TranscriptionContext
    ) async -> [String: Float] {
        var adjustedScores = baseScores
        
        // Apply adaptive weights based on user corrections
        for (language, weight) in adaptiveWeights {
            if let currentScore = adjustedScores[language] {
                adjustedScores[language] = currentScore * weight
            }
        }
        
        // Apply text-length based adjustments
        let lengthFactor = getLengthAdjustmentFactor(textLength: text.count)
        for (language, score) in adjustedScores {
            adjustedScores[language] = score * lengthFactor
        }
        
        // Normalize scores
        let totalScore = adjustedScores.values.reduce(0, +)
        if totalScore > 0 {
            for language in adjustedScores.keys {
                adjustedScores[language] = adjustedScores[language]! / totalScore
            }
        }
        
        return adjustedScores
    }
    
    private func applyContextualLearning(
        scores: [String: Float],
        context: TranscriptionContext
    ) async -> [String: Float] {
        var adjustedScores = scores
        
        // Find matching contextual patterns
        let matchingPatterns = contextualLearning.filter { pattern in
            pattern.matches(context: context)
        }
        
        // Apply contextual adjustments
        for pattern in matchingPatterns {
            let adjustment = pattern.getAdjustment()
            if let currentScore = adjustedScores[pattern.preferredLanguage] {
                adjustedScores[pattern.preferredLanguage] = min(1.0, currentScore + adjustment)
            }
        }
        
        return adjustedScores
    }
    
    private func applyPatternMatching(
        scores: [String: Float],
        text: String
    ) async -> [String: Float] {
        var adjustedScores = scores
        
        // Check for learned character patterns
        for (language, pattern) in languagePatterns {
            let patternMatch = pattern.calculateMatch(text: text)
            if let currentScore = adjustedScores[language] {
                adjustedScores[language] = currentScore + (patternMatch * 0.1)
            }
        }
        
        return adjustedScores
    }
    
    // MARK: - Pattern Learning
    private func updateLanguagePatterns(from correction: UserCorrection) async {
        let correctLang = correction.correctLanguage
        
        if var pattern = languagePatterns[correctLang] {
            pattern.addSample(text: correction.originalText)
            languagePatterns[correctLang] = pattern
        } else {
            languagePatterns[correctLang] = LanguagePattern(
                language: correctLang,
                samples: [correction.originalText]
            )
        }
    }
    
    private func updateContextualPatterns(from correction: UserCorrection) async {
        let existingPattern = contextualLearning.first { pattern in
            pattern.matches(context: correction.context) &&
            pattern.preferredLanguage == correction.correctLanguage
        }
        
        if var pattern = existingPattern {
            pattern.reinforcePattern()
        } else {
            let newPattern = ContextualPattern(
                context: correction.context,
                preferredLanguage: correction.correctLanguage,
                strength: 1.0
            )
            contextualLearning.append(newPattern)
        }
    }
    
    private func adjustAdaptiveWeights(from correction: UserCorrection) async {
        let correctLang = correction.correctLanguage
        let detectedLang = correction.detectedLanguage
        
        // Increase weight for correct language
        let currentCorrectWeight = adaptiveWeights[correctLang] ?? 1.0
        adaptiveWeights[correctLang] = min(2.0, currentCorrectWeight + learningRate)
        
        // Decrease weight for incorrectly detected language
        if correctLang != detectedLang {
            let currentIncorrectWeight = adaptiveWeights[detectedLang] ?? 1.0
            adaptiveWeights[detectedLang] = max(0.5, currentIncorrectWeight - learningRate)
        }
    }
    
    // MARK: - Model Retraining
    private func retrainPersonalizedModel() async {
        guard userCorrections.count >= retrainingThreshold else { return }
        
        // Prepare training data from user corrections
        let trainingData = prepareTrainingData()
        
        // Create personalized model using CreateML
        do {
            personalizedModel = try await createPersonalizedModel(trainingData: trainingData)
            await updateLearningProgress()
        } catch {
            print("Failed to retrain personalized model: \(error)")
        }
    }
    
    private func prepareTrainingData() -> [(text: String, language: String)] {
        return userCorrections.map { correction in
            (text: correction.originalText, language: correction.correctLanguage)
        }
    }
    
    private func createPersonalizedModel(trainingData: [(text: String, language: String)]) async throws -> MLModel {
        // This would use CreateML to create a personalized model
        // Simplified implementation
        throw MLModelError.conversionFailed // Placeholder
    }
    
    // MARK: - Utility Functions
    private func getLengthAdjustmentFactor(textLength: Int) -> Float {
        // Short texts are harder to classify accurately
        switch textLength {
        case 0...10: return 0.8
        case 11...30: return 0.9
        case 31...100: return 1.0
        case 101...500: return 1.1
        default: return 1.2
        }
    }
    
    private func calculateRLAdjustment(base: Float, final: Float) -> Float {
        return final - base
    }
    
    private func generatePredictionReasoning(
        baseML: LanguageDetectionResult,
        rlAdjusted: [String: Float],
        contextual: [String: Float],
        pattern: [String: Float]
    ) -> String {
        var reasoning = "Base ML: \(baseML.language) (\(String(format: "%.1f%%", baseML.confidence * 100)))"
        
        let rlChange = (rlAdjusted[baseML.language] ?? 0) - baseML.confidence
        if abs(rlChange) > 0.05 {
            reasoning += ", RL Adjustment: \(rlChange > 0 ? "+" : "")\(String(format: "%.1f%%", rlChange * 100))"
        }
        
        return reasoning
    }
    
    private func updateLearningProgress() async {
        let totalPossibleCorrections = Float(maxCorrections)
        learningProgress = min(1.0, Float(correctionsCount) / totalPossibleCorrections)
        
        // Calculate accuracy improvement
        if correctionsCount > 10 {
            let recentCorrections = Array(userCorrections.suffix(10))
            let recentAccuracy = calculateAccuracy(corrections: recentCorrections)
            
            if correctionsCount > 20 {
                let olderCorrections = Array(userCorrections.dropLast(10).suffix(10))
                let olderAccuracy = calculateAccuracy(corrections: olderCorrections)
                accuracyImprovement = recentAccuracy - olderAccuracy
            }
        }
    }
    
    private func calculateAccuracy(corrections: [UserCorrection]) -> Float {
        guard !corrections.isEmpty else { return 0.0 }
        
        let correctPredictions = corrections.filter { correction in
            correction.detectedLanguage == correction.correctLanguage
        }.count
        
        return Float(correctPredictions) / Float(corrections.count)
    }
    
    // MARK: - Data Persistence
    private func loadExistingLearningData() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "rlLearningData") {
            do {
                let decoder = JSONDecoder()
                userCorrections = try decoder.decode([UserCorrection].self, from: data)
                correctionsCount = userCorrections.count
            } catch {
                print("Failed to load learning data: \(error)")
            }
        }
    }
    
    private func saveLearningData() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(userCorrections)
            UserDefaults.standard.set(data, forKey: "rlLearningData")
        } catch {
            print("Failed to save learning data: \(error)")
        }
    }
    
    private func initializeAdaptiveWeights() {
        let languages = ["hi", "bn", "te", "ta", "mr", "gu", "kn", "ml", "ur", "pa", "or", "as", "ne"]
        for language in languages {
            adaptiveWeights[language] = 1.0
        }
    }
    
    // MARK: - Public Interface
    func getLearningStats() -> LearningStats {
        return LearningStats(
            totalCorrections: correctionsCount,
            learningProgress: learningProgress,
            accuracyImprovement: accuracyImprovement,
            activePatterns: languagePatterns.count,
            contextualPatterns: contextualLearning.count
        )
    }
    
    func resetLearning() {
        userCorrections.removeAll()
        languagePatterns.removeAll()
        contextualLearning.removeAll()
        correctionsCount = 0
        learningProgress = 0.0
        accuracyImprovement = 0.0
        initializeAdaptiveWeights()
        UserDefaults.standard.removeObject(forKey: "rlLearningData")
    }
}

// MARK: - Supporting Types

struct UserCorrection: Codable {
    let originalText: String
    let detectedLanguage: String
    let correctLanguage: String
    let originalConfidence: Float
    let timestamp: Date
    let context: TranscriptionContext
    let textLength: Int
    let wordCount: Int
}

struct TranscriptionContext: Codable {
    let timeOfDay: Int // Hour of day (0-23)
    let dayOfWeek: Int // 1-7
    let previousLanguage: String?
    let sessionLength: TimeInterval
    let backgroundNoise: NoiseLevel
}

enum NoiseLevel: String, Codable {
    case quiet, moderate, noisy, veryNoisy
}

struct LanguagePattern {
    let language: String
    var samples: [String]
    var characterFrequency: [Character: Int] = [:]
    var commonWords: Set<String> = []
    
    mutating func addSample(text: String) {
        samples.append(text)
        
        // Update character frequency
        for char in text {
            characterFrequency[char, default: 0] += 1
        }
        
        // Update common words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words where word.count > 2 {
            commonWords.insert(word.lowercased())
        }
    }
    
    func calculateMatch(text: String) -> Float {
        var score: Float = 0.0
        
        // Character frequency matching
        for char in text {
            if characterFrequency[char] != nil {
                score += 0.01
            }
        }
        
        // Common word matching
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            if commonWords.contains(word.lowercased()) {
                score += 0.1
            }
        }
        
        return min(1.0, score)
    }
}

struct ContextualPattern {
    let context: TranscriptionContext
    let preferredLanguage: String
    var strength: Float
    
    func matches(context: TranscriptionContext) -> Bool {
        return abs(self.context.timeOfDay - context.timeOfDay) <= 2 ||
               self.context.dayOfWeek == context.dayOfWeek ||
               self.context.previousLanguage == context.previousLanguage
    }
    
    mutating func reinforcePattern() {
        strength = min(2.0, strength + 0.1)
    }
    
    func getAdjustment() -> Float {
        return strength * 0.05
    }
}

struct EnhancedPrediction {
    let language: String
    let confidence: Float
    let baseMLConfidence: Float
    let rlAdjustment: Float
    let allScores: [String: Float]
    let reasoning: String
}

struct LearningStats {
    let totalCorrections: Int
    let learningProgress: Float
    let accuracyImprovement: Float
    let activePatterns: Int
    let contextualPatterns: Int
}
