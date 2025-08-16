import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject var vm: TranscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAdvancedSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: TalkNoteDesign.Spacing.lg) {
                    // Header
                    headerView
                    
                    // Quick Language Pairs
                    quickLanguagePairsView
                    
                    // Detailed Language Settings
                    detailedLanguageSettingsView
                    
                    // Advanced ML Settings
                    advancedSettingsView
                    
                    // Statistics
                    statisticsView
                }
                .padding(TalkNoteDesign.Spacing.md)
            }
            .navigationTitle("Language Settings")
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
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                HStack {
                    Image(systemName: "globe")
                        .font(.title)
                        .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    
                    VStack(alignment: .leading) {
                        Text("Multi-Language Support")
                            .font(TalkNoteDesign.Typography.headline)
                            .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                        
                        Text("Configure your preferred languages for real-time translation")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Current language pair indicator
                HStack {
                    languageChip(vm.sourceLanguage, isSource: true)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                    
                    languageChip(vm.targetLanguage, isSource: false)
                }
            }
        }
    }
    
    // MARK: - Quick Language Pairs
    
    private var quickLanguagePairsView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                Text("Quick Language Pairs")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                let popularPairs = [
                    ("hi", "en"), ("bn", "en"), ("ta", "en"),
                    ("te", "en"), ("mr", "en"), ("gu", "en")
                ]
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: TalkNoteDesign.Spacing.sm) {
                    ForEach(popularPairs.indices, id: \.self) { index in
                        let pair = popularPairs[index]
                        quickPairButton(from: pair.0, to: pair.1)
                    }
                }
            }
        }
    }
    
    // MARK: - Detailed Language Settings
    
    private var detailedLanguageSettingsView: some View {
        VStack(spacing: TalkNoteDesign.Spacing.md) {
            // Source Language Selection
            CardView {
                VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                    Label("Source Language (What you speak)", systemImage: "mic")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: TalkNoteDesign.Spacing.sm) {
                        ForEach(vm.supportedSources, id: \.self) { language in
                            languageSelectionButton(
                                language: language,
                                isSelected: vm.sourceLanguage == language,
                                action: { vm.sourceLanguage = language }
                            )
                        }
                    }
                }
            }
            
            // Target Language Selection
            CardView {
                VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                    Label("Target Language (Translation output)", systemImage: "text.bubble")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: TalkNoteDesign.Spacing.sm) {
                        ForEach(vm.supportedTargets, id: \.self) { language in
                            languageSelectionButton(
                                language: language,
                                isSelected: vm.targetLanguage == language,
                                action: { vm.targetLanguage = language }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Settings
    
    private var advancedSettingsView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                HStack {
                    Label("Advanced AI Settings", systemImage: "brain")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showingAdvancedSettings.toggle()
                        }
                    }) {
                        Image(systemName: showingAdvancedSettings ? "chevron.up" : "chevron.down")
                            .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    }
                }
                
                if showingAdvancedSettings {
                    VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                        // ML Learning Toggle
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Machine Learning")
                                    .font(TalkNoteDesign.Typography.callout)
                                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                                
                                Text("Learn from your corrections to improve accuracy")
                                    .font(TalkNoteDesign.Typography.caption)
                                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(SwitchToggleStyle(tint: TalkNoteDesign.Colors.primaryBlue))
                        }
                        
                        Divider()
                        
                        // Auto-detect Language
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Auto-detect Language")
                                    .font(TalkNoteDesign.Typography.callout)
                                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                                
                                Text("Automatically identify the spoken language")
                                    .font(TalkNoteDesign.Typography.caption)
                                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: .constant(true))
                                .toggleStyle(SwitchToggleStyle(tint: TalkNoteDesign.Colors.primaryBlue))
                        }
                        
                        Divider()
                        
                        // Confidence Threshold
                        VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                            Text("Translation Confidence Threshold")
                                .font(TalkNoteDesign.Typography.callout)
                                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                            
                            HStack {
                                Text("Low")
                                    .font(TalkNoteDesign.Typography.caption)
                                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                                
                                Slider(value: .constant(0.8), in: 0.1...1.0)
                                    .tint(TalkNoteDesign.Colors.primaryBlue)
                                
                                Text("High")
                                    .font(TalkNoteDesign.Typography.caption)
                                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Statistics
    
    private var statisticsView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                Label("Usage Statistics", systemImage: "chart.bar")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                HStack {
                    statisticItem(title: "Translations", value: "1,234", icon: "text.bubble")
                    Spacer()
                    statisticItem(title: "Accuracy", value: "94%", icon: "checkmark.circle")
                    Spacer()
                    statisticItem(title: "Languages", value: "8", icon: "globe")
                }
                
                // Reset statistics button
                Button("Reset Statistics") {
                    // Reset statistics logic
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func languageChip(_ language: String, isSource: Bool) -> some View {
        HStack(spacing: TalkNoteDesign.Spacing.xs) {
            Text(getLanguageFlag(language))
                .font(.title3)
            
            Text(getLanguageDisplayName(language))
                .font(TalkNoteDesign.Typography.caption)
                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
        }
        .padding(.horizontal, TalkNoteDesign.Spacing.sm)
        .padding(.vertical, TalkNoteDesign.Spacing.xs)
        .background(
            isSource ? TalkNoteDesign.Colors.primaryBlue.opacity(0.1) : TalkNoteDesign.Colors.accentOrange.opacity(0.1)
        )
        .cornerRadius(TalkNoteDesign.CornerRadius.small)
    }
    
    private func quickPairButton(from: String, to: String) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                vm.sourceLanguage = from
                vm.targetLanguage = to
            }
        }) {
            HStack {
                Text(getLanguageFlag(from))
                Image(systemName: "arrow.right")
                    .font(.caption)
                Text(getLanguageFlag(to))
            }
            .font(.caption)
            .padding(.horizontal, TalkNoteDesign.Spacing.sm)
            .padding(.vertical, TalkNoteDesign.Spacing.xs)
            .background(
                vm.sourceLanguage == from && vm.targetLanguage == to ?
                TalkNoteDesign.Colors.primaryBlue.opacity(0.2) :
                TalkNoteDesign.Colors.surfaceSecondary
            )
            .cornerRadius(TalkNoteDesign.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func languageSelectionButton(language: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: TalkNoteDesign.Spacing.xs) {
                Text(getLanguageFlag(language))
                    .font(.title2)
                
                Text(getLanguageDisplayName(language))
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(isSelected ? .white : TalkNoteDesign.Colors.textPrimary)
            }
            .padding(TalkNoteDesign.Spacing.sm)
            .background(
                isSelected ? TalkNoteDesign.Colors.primaryBlue : TalkNoteDesign.Colors.surfaceSecondary
            )
            .cornerRadius(TalkNoteDesign.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statisticItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: TalkNoteDesign.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
            
            Text(value)
                .font(TalkNoteDesign.Typography.headline)
                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
            
            Text(title)
                .font(TalkNoteDesign.Typography.caption)
                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getLanguageDisplayName(_ code: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "hi": "Hindi",
            "bn": "Bengali",
            "ta": "Tamil",
            "te": "Telugu",
            "mr": "Marathi",
            "gu": "Gujarati",
            "kn": "Kannada"
        ]
        return languageNames[code] ?? code.uppercased()
    }
    
    private func getLanguageFlag(_ code: String) -> String {
        let flags: [String: String] = [
            "en": "🇺🇸",
            "hi": "🇮🇳",
            "bn": "🇧🇩",
            "ta": "🇮🇳",
            "te": "🇮🇳",
            "mr": "🇮🇳",
            "gu": "🇮🇳",
            "kn": "🇮🇳"
        ]
        return flags[code] ?? "🌐"
    }
}
