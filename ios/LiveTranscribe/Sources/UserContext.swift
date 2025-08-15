import Foundation

/// Represents the user's context and environment for reinforcement learning
public struct UserContext: Codable {
    let timestamp: Date
    let deviceOrientation: String
    let backgroundNoise: NoiseLevel
    let speakingSpeed: SpeakingSpeed
    let languagePreference: String
    let sessionDuration: TimeInterval
    let previousAccuracy: Double
    
    public enum NoiseLevel: String, Codable, CaseIterable {
        case quiet = "quiet"
        case moderate = "moderate"
        case noisy = "noisy"
        
        var numericValue: Double {
            switch self {
            case .quiet: return 0.1
            case .moderate: return 0.5
            case .noisy: return 0.9
            }
        }
    }
    
    public enum SpeakingSpeed: String, Codable, CaseIterable {
        case slow = "slow"
        case normal = "normal"
        case fast = "fast"
        
        var numericValue: Double {
            switch self {
            case .slow: return 0.3
            case .normal: return 0.6
            case .fast: return 0.9
            }
        }
    }
    
    public init(
        timestamp: Date = Date(),
        deviceOrientation: String = "portrait",
        backgroundNoise: NoiseLevel = .moderate,
        speakingSpeed: SpeakingSpeed = .normal,
        languagePreference: String = "en",
        sessionDuration: TimeInterval = 0,
        previousAccuracy: Double = 0.8
    ) {
        self.timestamp = timestamp
        self.deviceOrientation = deviceOrientation
        self.backgroundNoise = backgroundNoise
        self.speakingSpeed = speakingSpeed
        self.languagePreference = languagePreference
        self.sessionDuration = sessionDuration
        self.previousAccuracy = previousAccuracy
    }
    
    /// Convert context to feature vector for ML processing
    public func toFeatureVector() -> [Double] {
        return [
            backgroundNoise.numericValue,
            speakingSpeed.numericValue,
            sessionDuration / 3600.0, // normalize to hours
            previousAccuracy,
            Double(languagePreference == "en" ? 1 : 0) // simple language encoding
        ]
    }
}
