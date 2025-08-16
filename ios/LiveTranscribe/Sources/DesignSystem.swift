import SwiftUI

/// Modern UI design system for TalkNote
struct TalkNoteDesign {
    
    // MARK: - Colors
    struct Colors {
        // Primary brand colors
        static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let primaryDark = Color(red: 0.0, green: 0.32, blue: 0.8)
        static let primaryLight = Color(red: 0.4, green: 0.7, blue: 1.0)
        
        // Accent colors
        static let accent = Color(red: 0.0, green: 0.32, blue: 0.8) // Primary accent color
        static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.0)
        static let accentGreen = Color(red: 0.2, green: 0.8, blue: 0.2)
        static let accentRed = Color(red: 1.0, green: 0.3, blue: 0.3)
        
        // Surface colors
        static let surface = Color(.systemBackground)
        static let surfaceSecondary = Color(.secondarySystemBackground)
        static let surfaceTertiary = Color(.tertiarySystemBackground)
        
        // Text colors
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        
        // Gradient colors
        static let gradientStart = primaryLight
        static let gradientEnd = primaryDark
        
        // Security status colors
        static let secureGreen = Color(red: 0.0, green: 0.8, blue: 0.0)
        static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
        static let dangerRed = Color(red: 1.0, green: 0.2, blue: 0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 28
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.2)
        static let dark = Color.black.opacity(0.3)
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TalkNoteDesign.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, TalkNoteDesign.Spacing.lg)
            .padding(.vertical, TalkNoteDesign.Spacing.md)
            .background(
                LinearGradient(
                    colors: isDestructive ? 
                        [TalkNoteDesign.Colors.accentRed, TalkNoteDesign.Colors.accentRed.opacity(0.8)] :
                        [TalkNoteDesign.Colors.gradientStart, TalkNoteDesign.Colors.gradientEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(TalkNoteDesign.CornerRadius.medium)
            .shadow(color: TalkNoteDesign.Shadow.medium, radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TalkNoteDesign.Typography.callout)
            .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
            .padding(.horizontal, TalkNoteDesign.Spacing.md)
            .padding(.vertical, TalkNoteDesign.Spacing.sm)
            .background(TalkNoteDesign.Colors.surfaceSecondary)
            .cornerRadius(TalkNoteDesign.CornerRadius.small)
            .overlay(
                RoundedRectangle(cornerRadius: TalkNoteDesign.CornerRadius.small)
                    .stroke(TalkNoteDesign.Colors.primaryBlue, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card View

struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = TalkNoteDesign.Spacing.md, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(TalkNoteDesign.Colors.surface)
            .cornerRadius(TalkNoteDesign.CornerRadius.medium)
            .shadow(color: TalkNoteDesign.Shadow.light, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Animated Microphone Button

struct MicrophoneButton: View {
    @Binding var isRecording: Bool
    let action: () -> Void
    var isDisabled: Bool = false
    
    @State private var pulseAnimation = false
    @State private var rotationAnimation = false
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            ZStack {
                // Pulse effect when recording (not when disabled)
                if isRecording && !isDisabled {
                    Circle()
                        .fill(TalkNoteDesign.Colors.accentRed.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.8)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: pulseAnimation)
                }
                
                // Main button
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isDisabled ? 
                                    [Color.gray.opacity(0.3), Color.gray.opacity(0.5)] :
                                    isRecording ? 
                                        [TalkNoteDesign.Colors.accentRed, TalkNoteDesign.Colors.accentRed.opacity(0.7)] :
                                        [TalkNoteDesign.Colors.gradientStart, TalkNoteDesign.Colors.gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: isDisabled ? "mic.slash.fill" : isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(isDisabled ? Color.gray : .white)
                        .rotationEffect(Angle(degrees: rotationAnimation ? 360 : 0))
                }
                .shadow(color: isDisabled ? Color.clear : TalkNoteDesign.Shadow.medium, radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onAppear {
            if isRecording {
                pulseAnimation = true
            }
        }
        .onChange(of: isRecording) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                if newValue {
                    pulseAnimation = true
                    rotationAnimation = true
                } else {
                    pulseAnimation = false
                    rotationAnimation = false
                }
            }
        }
    }
}

// MARK: - Language Picker Card

struct LanguagePickerCard: View {
    @Binding var selectedLanguage: String
    let supportedLanguages: [String]
    let title: String
    @State private var isExpanded = false
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                Label(title, systemImage: "globe")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Menu {
                    ForEach(supportedLanguages, id: \.self) { language in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLanguage = language
                            }
                        }) {
                            HStack {
                                Text(getLanguageDisplayName(language))
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(TalkNoteDesign.Colors.accentGreen)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(getLanguageDisplayName(selectedLanguage))
                            .font(TalkNoteDesign.Typography.callout)
                            .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    .padding(TalkNoteDesign.Spacing.md)
                    .background(TalkNoteDesign.Colors.surfaceSecondary)
                    .cornerRadius(TalkNoteDesign.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: TalkNoteDesign.CornerRadius.medium)
                            .stroke(selectedLanguage.isEmpty ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
                }
            }
        }
    }
    
    private func getLanguageDisplayName(_ code: String) -> String {
        let languageNames: [String: String] = [
            "en": "🇺🇸 English",
            "hi": "🇮🇳 Hindi",
            "bn": "🇧🇩 Bengali",
            "ta": "🇮🇳 Tamil", 
            "te": "🇮🇳 Telugu",
            "mr": "🇮🇳 Marathi",
            "gu": "🇮🇳 Gujarati",
            "kn": "🇮🇳 Kannada",
            "ur": "🇵🇰 Urdu",
            "es": "🇪🇸 Spanish",
            "fr": "🇫🇷 French", 
            "de": "🇩🇪 German",
            "zh-Hans": "🇨🇳 Chinese",
            "ar": "🇸🇦 Arabic",
            "ru": "🇷🇺 Russian",
            "ja": "🇯🇵 Japanese",
            "ko": "🇰🇷 Korean"
        ]
        return languageNames[code] ?? "🌍 \(code.uppercased())"
    }
}

// MARK: - Security Status Indicator

struct SecurityStatusView: View {
    @ObservedObject var securityManager: SecurityManager
    
    var body: some View {
        HStack(spacing: TalkNoteDesign.Spacing.sm) {
            Image(systemName: securityStatusIcon)
                .foregroundColor(securityStatusColor)
                .font(.caption)
            
            Text(securityStatusText)
                .font(TalkNoteDesign.Typography.caption)
                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
        }
        .padding(.horizontal, TalkNoteDesign.Spacing.sm)
        .padding(.vertical, TalkNoteDesign.Spacing.xs)
        .background(securityStatusColor.opacity(0.1))
        .cornerRadius(TalkNoteDesign.CornerRadius.small)
    }
    
    private var securityStatusIcon: String {
        securityManager.isAppSecure ? "shield.fill" : "shield.slash.fill"
    }
    
    private var securityStatusColor: Color {
        securityManager.isAppSecure ? TalkNoteDesign.Colors.secureGreen : TalkNoteDesign.Colors.dangerRed
    }
    
    private var securityStatusText: String {
        securityManager.isAppSecure ? "Secure" : "Security Warning"
    }
}

// MARK: - Animated Wave Form

struct WaveFormView: View {
    @State private var animationValues: [CGFloat] = Array(repeating: 0.1, count: 5)
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(TalkNoteDesign.Colors.primaryBlue)
                    .frame(width: 4, height: animationValues[index] * 40)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animationValues[index]
                    )
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func startAnimation() {
        for i in 0..<5 {
            animationValues[i] = CGFloat.random(in: 0.3...1.0)
        }
    }
    
    private func stopAnimation() {
        for i in 0..<5 {
            animationValues[i] = 0.1
        }
    }
}
