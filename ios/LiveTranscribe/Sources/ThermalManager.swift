import Foundation
import UIKit

/// Samsung-style thermal management to prevent device overheating
/// Monitors temperature and automatically adjusts transcription settings
class ThermalManager: ObservableObject {
    
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var isThrottled: Bool = false
    @Published var heatReductionActive: Bool = false
    @Published var batteryOptimizationEnabled: Bool = true
    
    private var thermalStateObservation: NSObjectProtocol?
    
    init() {
        startThermalMonitoring()
    }
    
    deinit {
        stopThermalMonitoring()
    }
    
    private func startThermalMonitoring() {
        // Monitor thermal state changes
        thermalStateObservation = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateThermalState()
        }
        
        // Initial thermal state check
        updateThermalState()
    }
    
    private func stopThermalMonitoring() {
        if let observation = thermalStateObservation {
            NotificationCenter.default.removeObserver(observation)
        }
    }
    
    private func updateThermalState() {
        let currentState = ProcessInfo.processInfo.thermalState
        
        DispatchQueue.main.async {
            self.thermalState = currentState
            
            switch currentState {
            case .nominal:
                self.isThrottled = false
                self.heatReductionActive = false
                
            case .fair:
                // Samsung-style: Start gentle optimization
                self.isThrottled = false
                self.heatReductionActive = true
                
            case .serious:
                // Samsung-style: Reduce processing intensity
                self.isThrottled = true
                self.heatReductionActive = true
                
            case .critical:
                // Samsung-style: Maximum heat reduction
                self.isThrottled = true
                self.heatReductionActive = true
                
            @unknown default:
                self.isThrottled = false
                self.heatReductionActive = false
            }
            
            print("🌡️ Thermal state: \(self.thermalStateDescription)")
        }
    }
    
    var thermalStateDescription: String {
        switch thermalState {
        case .nominal: return "Normal"
        case .fair: return "Warm"
        case .serious: return "Hot (Optimizing)"
        case .critical: return "Very Hot (Throttled)"
        @unknown default: return "Unknown"
        }
    }
    
    // Samsung-style temperature optimization recommendations
    func getOptimizedTranscriptionSettings() -> (model: String, quality: String, frequency: TimeInterval) {
        switch thermalState {
        case .nominal:
            return ("Large (98%)", "Maximum", 0.1) // Full performance
            
        case .fair:
            return ("Medium (95%)", "High", 0.2) // Slight optimization
            
        case .serious:
            return ("Base (88%)", "Balanced", 0.5) // Significant optimization
            
        case .critical:
            return ("Tiny (82%)", "Power Saving", 1.0) // Maximum heat reduction
            
        @unknown default:
            return ("Base (88%)", "Balanced", 0.2)
        }
    }
    
    // Battery level awareness (Samsung-style)
    var batteryLevel: Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }
    
    var batteryState: UIDevice.BatteryState {
        return UIDevice.current.batteryState
    }
    
    func shouldReducePerformanceForBattery() -> Bool {
        let level = batteryLevel
        let state = batteryState
        
        return (level < 0.20 && state != .charging) || // Below 20% and not charging
               (level < 0.10) // Below 10% regardless of charging state
    }
    
    // Samsung-style smart recommendations
    func getSmartRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if heatReductionActive {
            recommendations.append("🌡️ Device is warm - using optimized settings")
        }
        
        if shouldReducePerformanceForBattery() {
            recommendations.append("🔋 Low battery - consider power saving mode")
        }
        
        if thermalState == .critical {
            recommendations.append("⚠️ Device very hot - transcription may pause")
        }
        
        if isThrottled {
            recommendations.append("🐌 Performance reduced to prevent overheating")
        }
        
        return recommendations
    }
    
    // Methods for transcription service integration
    func canUseHighPerformanceModel() -> Bool {
        return thermalState == .nominal && !shouldReducePerformanceForBattery()
    }
    
    func getRecommendedProcessingInterval() -> TimeInterval {
        return getOptimizedTranscriptionSettings().frequency
    }
    
    func getRecommendedModelComplexity() -> String {
        return getOptimizedTranscriptionSettings().model
    }
}

// Samsung-style thermal state extensions
extension ProcessInfo.ThermalState {
    var emoji: String {
        switch self {
        case .nominal: return "❄️"
        case .fair: return "🌤️"
        case .serious: return "🔥"
        case .critical: return "🚨"
        @unknown default: return "❓"
        }
    }
    
    var performance: String {
        switch self {
        case .nominal: return "Maximum Performance"
        case .fair: return "High Performance"
        case .serious: return "Balanced Performance"
        case .critical: return "Power Saving Mode"
        @unknown default: return "Unknown"
        }
    }
}
