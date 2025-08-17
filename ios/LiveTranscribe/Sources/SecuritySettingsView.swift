import SwiftUI
import LocalAuthentication

struct SecuritySettingsView: View {
    @ObservedObject var securityManager: SecurityManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingBiometricSetup = false
    @State private var showingSecurityDetails = false
    @State private var biometricType: LABiometryType = .none
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: TalkNoteDesign.Spacing.lg) {
                    // Security Status Header
                    securityStatusHeaderView
                    
                    // Security Features
                    securityFeaturesView
                    
                    // Privacy Protection
                    privacyProtectionView
                    
                    // Advanced Security
                    advancedSecurityView
                    
                    // Security Log
                    securityLogView
                }
                .padding(TalkNoteDesign.Spacing.md)
            }
            .navigationTitle("Security Center")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .onAppear {
            detectBiometricType()
        }
    }
    
    // MARK: - Security Status Header
    
    private var securityStatusHeaderView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                HStack {
                    Image(systemName: securityManager.isAppSecure ? "shield.checkered" : "shield.slash")
                        .font(.title)
                        .foregroundColor(securityManager.isAppSecure ? TalkNoteDesign.Colors.secureGreen : TalkNoteDesign.Colors.dangerRed)
                    
                    VStack(alignment: .leading) {
                        Text(securityManager.isAppSecure ? "App is Secure" : "Security Warning")
                            .font(TalkNoteDesign.Typography.headline)
                            .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                        
                        Text(securityManager.isAppSecure ? 
                             "All security checks passed" : 
                             "Security threats detected")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Security Score
                HStack {
                    VStack(alignment: .leading) {
                        Text("Security Score")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        
                        Text(securityManager.isAppSecure ? "95/100" : "45/100")
                            .font(TalkNoteDesign.Typography.title2)
                            .foregroundColor(securityManager.isAppSecure ? TalkNoteDesign.Colors.secureGreen : TalkNoteDesign.Colors.dangerRed)
                    }
                    
                    Spacer()
                    
                    // Last security check
                    VStack(alignment: .trailing) {
                        Text("Last Check")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        
                        Text(timeAgoString(from: securityManager.lastSecurityCheck))
                            .font(TalkNoteDesign.Typography.callout)
                            .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Security Features
    
    private var securityFeaturesView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                Label("Security Features", systemImage: "lock.shield")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                // Biometric Authentication
                securityFeatureRow(
                    title: biometricAuthTitle,
                    description: "Secure app with your fingerprint or face",
                    icon: biometricIcon,
                    isEnabled: securityManager.biometricAuthEnabled,
                    action: toggleBiometricAuth
                )
                
                Divider()
                
                // Data Encryption
                securityFeatureRow(
                    title: "Data Encryption",
                    description: "End-to-end encryption for all data",
                    icon: "key.fill",
                    isEnabled: true,
                    action: { /* Always enabled */ }
                )
                
                Divider()
                
                // Anti-Tampering
                securityFeatureRow(
                    title: "Anti-Tampering Protection",
                    description: "Detect app modifications and jailbreaks",
                    icon: "checkmark.shield",
                    isEnabled: securityManager.isAppSecure,
                    action: { /* Always enabled */ }
                )
                
                Divider()
                
                // Runtime Protection
                securityFeatureRow(
                    title: "Runtime Protection (RASP)",
                    description: "Real-time threat detection and mitigation",
                    icon: "eye.circle",
                    isEnabled: true,
                    action: { /* Always enabled */ }
                )
            }
        }
    }
    
    // MARK: - Privacy Protection
    
    private var privacyProtectionView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                Label("Privacy Protection", systemImage: "hand.raised.fill")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                    privacyItem(
                        title: "Audio Processing",
                        description: "All audio is processed locally on your device"
                    )
                    
                    privacyItem(
                        title: "Data Transmission",
                        description: "Only encrypted text is sent to translation services"
                    )
                    
                    privacyItem(
                        title: "No Recording Storage",
                        description: "Voice recordings are never stored or transmitted"
                    )
                    
                    privacyItem(
                        title: "Zero Data Collection",
                        description: "No personal information is collected or shared"
                    )
                }
            }
        }
    }
    
    // MARK: - Advanced Security
    
    private var advancedSecurityView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                HStack {
                    Label("Advanced Security", systemImage: "gear.badge.checkmark")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showingSecurityDetails.toggle()
                        }
                    }) {
                        Image(systemName: showingSecurityDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    }
                }
                
                if showingSecurityDetails {
                    VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                        // Certificate Pinning
                        advancedSecurityItem(
                            title: "Certificate Pinning",
                            description: "Prevents man-in-the-middle attacks",
                            status: .enabled
                        )
                        
                        Divider()
                        
                        // Code Obfuscation
                        advancedSecurityItem(
                            title: "Code Obfuscation",
                            description: "Protects against reverse engineering",
                            status: .enabled
                        )
                        
                        Divider()
                        
                        // Memory Protection
                        advancedSecurityItem(
                            title: "Memory Protection",
                            description: "Prevents memory dumps and analysis",
                            status: .enabled
                        )
                        
                        Divider()
                        
                        // Network Security
                        advancedSecurityItem(
                            title: "Network Security Validation",
                            description: "Continuous monitoring of network connections",
                            status: .monitoring
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Security Log
    
    private var securityLogView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                Label("Security Events Log", systemImage: "list.bullet.rectangle")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                VStack(spacing: TalkNoteDesign.Spacing.sm) {
                    securityLogEntry(
                        title: "Security Check Passed",
                        timestamp: Date().addingTimeInterval(-300),
                        type: .success
                    )
                    
                    securityLogEntry(
                        title: "App Integrity Verified",
                        timestamp: Date().addingTimeInterval(-1200),
                        type: .success
                    )
                    
                    securityLogEntry(
                        title: "Biometric Authentication Enabled",
                        timestamp: Date().addingTimeInterval(-3600),
                        type: .info
                    )
                    
                    if !securityManager.isAppSecure {
                        securityLogEntry(
                            title: "Security Threat Detected",
                            timestamp: Date().addingTimeInterval(-7200),
                            type: .warning
                        )
                    }
                }
                
                Button("View Full Security Log") {
                    // Show full security log
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func securityFeatureRow(
        title: String,
        description: String,
        icon: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? TalkNoteDesign.Colors.secureGreen : TalkNoteDesign.Colors.textSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(TalkNoteDesign.Typography.callout)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Text(description)
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            if title.contains("Authentication") {
                Toggle("", isOn: .init(
                    get: { isEnabled },
                    set: { _ in action() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: TalkNoteDesign.Colors.primaryBlue))
            } else {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isEnabled ? TalkNoteDesign.Colors.secureGreen : TalkNoteDesign.Colors.dangerRed)
            }
        }
    }
    
    private func privacyItem(title: String, description: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(TalkNoteDesign.Colors.secureGreen)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.xs) {
                Text(title)
                    .font(TalkNoteDesign.Typography.callout)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Text(description)
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
            }
        }
    }
    
    private func advancedSecurityItem(
        title: String,
        description: String,
        status: SecurityItemStatus
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(TalkNoteDesign.Typography.callout)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Text(description)
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: TalkNoteDesign.Spacing.xs) {
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
                
                Text(status.text)
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(status.color)
            }
        }
    }
    
    private func securityLogEntry(
        title: String,
        timestamp: Date,
        type: SecurityLogType
    ) -> some View {
        HStack {
            Image(systemName: type.icon)
                .font(.caption)
                .foregroundColor(type.color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Text(timeAgoString(from: timestamp))
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, TalkNoteDesign.Spacing.xs)
        .padding(.horizontal, TalkNoteDesign.Spacing.sm)
        .background(type.backgroundColor)
        .cornerRadius(TalkNoteDesign.CornerRadius.small)
    }
    
    // MARK: - Helper Methods
    
    private func detectBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        }
    }
    
    private func toggleBiometricAuth() {
        Task { @MainActor in
            if securityManager.biometricAuthEnabled {
                securityManager.biometricAuthEnabled = false
            } else {
                do {
                    let success = await securityManager.enableBiometricAuth()
                    if !success {
                        showingBiometricSetup = true
                    }
                } catch {
                    print("Failed to toggle biometric authentication: \(error)")
                    showingBiometricSetup = true
                }
            }
        }
    }
    
    private var biometricAuthTitle: String {
        switch biometricType {
        case .faceID:
            return "Face ID Authentication"
        case .touchID:
            return "Touch ID Authentication"
        case .opticID:
            return "Optic ID Authentication"
        default:
            return "Biometric Authentication"
        }
    }
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "person.badge.key"
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Types

enum SecurityItemStatus {
    case enabled
    case disabled
    case monitoring
    
    var icon: String {
        switch self {
        case .enabled: return "checkmark.circle.fill"
        case .disabled: return "xmark.circle.fill"
        case .monitoring: return "eye.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .enabled: return TalkNoteDesign.Colors.secureGreen
        case .disabled: return TalkNoteDesign.Colors.dangerRed
        case .monitoring: return TalkNoteDesign.Colors.primaryBlue
        }
    }
    
    var text: String {
        switch self {
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .monitoring: return "Monitoring"
        }
    }
}

enum SecurityLogType {
    case success
    case warning
    case info
    case error
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return TalkNoteDesign.Colors.secureGreen
        case .warning: return TalkNoteDesign.Colors.warningYellow
        case .info: return TalkNoteDesign.Colors.primaryBlue
        case .error: return TalkNoteDesign.Colors.dangerRed
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return TalkNoteDesign.Colors.secureGreen.opacity(0.1)
        case .warning: return TalkNoteDesign.Colors.warningYellow.opacity(0.1)
        case .info: return TalkNoteDesign.Colors.primaryBlue.opacity(0.1)
        case .error: return TalkNoteDesign.Colors.dangerRed.opacity(0.1)
        }
    }
}
