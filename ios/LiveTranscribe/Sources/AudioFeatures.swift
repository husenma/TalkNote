import Foundation
import AVFoundation

/// Represents audio characteristics extracted from speech input
public struct AudioFeatures: Codable {
    let amplitude: Double
    let frequency: Double
    let clarity: Double
    let noiseLevel: Double
    let speechRate: Double
    let pitch: Double
    let duration: TimeInterval
    let energyLevel: Double
    
    public init(
        amplitude: Double = 0.5,
        frequency: Double = 440.0,
        clarity: Double = 0.8,
        noiseLevel: Double = 0.2,
        speechRate: Double = 150.0, // words per minute
        pitch: Double = 200.0, // Hz
        duration: TimeInterval = 1.0,
        energyLevel: Double = 0.6
    ) {
        self.amplitude = amplitude
        self.frequency = frequency
        self.clarity = clarity
        self.noiseLevel = noiseLevel
        self.speechRate = speechRate
        self.pitch = pitch
        self.duration = duration
        self.energyLevel = energyLevel
    }
    
    /// Extract basic audio features from audio buffer (simplified)
    public static func extract(from buffer: AVAudioPCMBuffer?) -> AudioFeatures {
        guard let buffer = buffer,
              let channelData = buffer.floatChannelData else {
            return AudioFeatures()
        }
        
        let frameLength = Int(buffer.frameLength)
        let channel = channelData[0]
        
        // Calculate basic features
        var sum: Float = 0
        var maxAmplitude: Float = 0
        
        for i in 0..<frameLength {
            let sample = channel[i]
            sum += abs(sample)
            maxAmplitude = max(maxAmplitude, abs(sample))
        }
        
        let averageAmplitude = sum / Float(frameLength)
        
        return AudioFeatures(
            amplitude: Double(maxAmplitude),
            frequency: 440.0, // Default, would need FFT for real frequency analysis
            clarity: Double(1.0 - (averageAmplitude * 0.5)), // Simple clarity metric
            noiseLevel: Double(averageAmplitude),
            speechRate: 150.0, // Default, would need speech analysis
            pitch: 200.0, // Default, would need pitch detection
            duration: Double(frameLength) / buffer.format.sampleRate,
            energyLevel: Double(averageAmplitude)
        )
    }
    
    /// Convert audio features to normalized vector for ML processing
    public func toFeatureVector() -> [Double] {
        return [
            min(amplitude, 1.0), // clamp to [0,1]
            frequency / 1000.0, // normalize frequency
            clarity,
            noiseLevel,
            speechRate / 300.0, // normalize speech rate
            pitch / 500.0, // normalize pitch
            min(duration, 10.0) / 10.0, // normalize duration to max 10 seconds
            energyLevel
        ]
    }
    
    /// Quality score based on audio characteristics
    var qualityScore: Double {
        let clarityWeight = 0.4
        let noiseWeight = 0.3
        let amplitudeWeight = 0.3
        
        return (clarity * clarityWeight) + 
               ((1.0 - noiseLevel) * noiseWeight) + 
               (amplitude * amplitudeWeight)
    }
}
