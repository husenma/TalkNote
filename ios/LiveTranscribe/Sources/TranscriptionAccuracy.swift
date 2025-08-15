import Foundation

/// Represents the accuracy metrics for transcription and translation
public struct TranscriptionAccuracy: Codable {
    let speechToTextAccuracy: Double
    let translationAccuracy: Double
    let overallConfidence: Double
    let wordErrorRate: Double
    let characterErrorRate: Double
    let languageDetectionAccuracy: Double
    let timestamp: Date
    
    public init(
        speechToTextAccuracy: Double = 0.85,
        translationAccuracy: Double = 0.80,
        overallConfidence: Double = 0.82,
        wordErrorRate: Double = 0.15,
        characterErrorRate: Double = 0.08,
        languageDetectionAccuracy: Double = 0.90,
        timestamp: Date = Date()
    ) {
        self.speechToTextAccuracy = speechToTextAccuracy
        self.translationAccuracy = translationAccuracy
        self.overallConfidence = overallConfidence
        self.wordErrorRate = wordErrorRate
        self.characterErrorRate = characterErrorRate
        self.languageDetectionAccuracy = languageDetectionAccuracy
        self.timestamp = timestamp
    }
    
    /// Calculate composite accuracy score
    var compositeScore: Double {
        let weights: [Double] = [0.4, 0.3, 0.2, 0.1]
        let scores = [
            speechToTextAccuracy,
            translationAccuracy,
            languageDetectionAccuracy,
            1.0 - wordErrorRate // Convert error rate to accuracy
        ]
        
        return zip(weights, scores).map(*).reduce(0, +)
    }
    
    /// Determine if this accuracy is better than another
    public func isBetterThan(_ other: TranscriptionAccuracy) -> Bool {
        return self.compositeScore > other.compositeScore
    }
    
    /// Create accuracy metrics from transcription results
    public static func calculate(
        originalText: String,
        transcribedText: String,
        translatedText: String,
        expectedTranslation: String? = nil,
        confidence: Float
    ) -> TranscriptionAccuracy {
        
        // Simple word error rate calculation
        let originalWords = originalText.components(separatedBy: .whitespaces)
        let transcribedWords = transcribedText.components(separatedBy: .whitespaces)
        
        let maxLength = max(originalWords.count, transcribedWords.count)
        var errors = 0
        
        for i in 0..<maxLength {
            let original = i < originalWords.count ? originalWords[i] : ""
            let transcribed = i < transcribedWords.count ? transcribedWords[i] : ""
            
            if original.lowercased() != transcribed.lowercased() {
                errors += 1
            }
        }
        
        let wordErrorRate = maxLength > 0 ? Double(errors) / Double(maxLength) : 0.0
        let speechAccuracy = max(0.0, 1.0 - wordErrorRate)
        
        // Character error rate (simplified)
        let charErrorRate = calculateCharacterErrorRate(originalText, transcribedText)
        
        // Translation accuracy (if expected translation provided)
        var translationAccuracy = 0.8 // default assumption
        if let expected = expectedTranslation {
            translationAccuracy = calculateTranslationAccuracy(translatedText, expected)
        }
        
        return TranscriptionAccuracy(
            speechToTextAccuracy: speechAccuracy,
            translationAccuracy: translationAccuracy,
            overallConfidence: Double(confidence),
            wordErrorRate: wordErrorRate,
            characterErrorRate: charErrorRate,
            languageDetectionAccuracy: 0.9 // default, would need actual detection metrics
        )
    }
    
    private static func calculateCharacterErrorRate(_ original: String, _ transcribed: String) -> Double {
        let originalChars = Array(original.lowercased())
        let transcribedChars = Array(transcribed.lowercased())
        
        let maxLength = max(originalChars.count, transcribedChars.count)
        guard maxLength > 0 else { return 0.0 }
        
        var errors = 0
        for i in 0..<maxLength {
            let originalChar = i < originalChars.count ? originalChars[i] : Character(" ")
            let transcribedChar = i < transcribedChars.count ? transcribedChars[i] : Character(" ")
            
            if originalChar != transcribedChar {
                errors += 1
            }
        }
        
        return Double(errors) / Double(maxLength)
    }
    
    private static func calculateTranslationAccuracy(_ translated: String, _ expected: String) -> Double {
        // Simple similarity calculation - in production, use BLEU score or similar
        let translatedWords = Set(translated.lowercased().components(separatedBy: .whitespaces))
        let expectedWords = Set(expected.lowercased().components(separatedBy: .whitespaces))
        
        let intersection = translatedWords.intersection(expectedWords)
        let union = translatedWords.union(expectedWords)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
}
