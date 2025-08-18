import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject var vm: TranscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAdvancedSettings = false
    @State private var showingLanguageSettings = false
    @State private var showingModelSettings = false
    
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
                    
                    // Model Selection Settings
                    modelSelectionView
                    
                    // Audio Enhancement Settings
                    audioSettingsView
                    
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
    
    // MARK: - Model Selection Cards
    
    private func modelSelectionCard(model: TranscriptionModel) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                vm.selectedTranscriptionModel = model
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.rawValue)
                            .font(TalkNoteDesign.Typography.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(vm.selectedTranscriptionModel == model ? .white : TalkNoteDesign.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(vm.dynamicAccuracy.isEmpty ? "Real-time" : vm.dynamicAccuracy)
                            .font(TalkNoteDesign.Typography.caption)
                            .fontWeight(.bold)
                            .foregroundColor(vm.selectedTranscriptionModel == model ? .white : TalkNoteDesign.Colors.primaryBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                vm.selectedTranscriptionModel == model ? 
                                Color.white.opacity(0.2) : 
                                TalkNoteDesign.Colors.primaryBlue.opacity(0.1)
                            )
                            .cornerRadius(10)
                    }
                    
                    Text(model.description)
                        .font(TalkNoteDesign.Typography.caption)
                        .foregroundColor(vm.selectedTranscriptionModel == model ? .white.opacity(0.8) : TalkNoteDesign.Colors.textSecondary)
                }
                
                if vm.selectedTranscriptionModel == model {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(TalkNoteDesign.Spacing.md)
            .background(
                vm.selectedTranscriptionModel == model ? 
                TalkNoteDesign.Colors.primaryBlue : 
                TalkNoteDesign.Colors.surfaceSecondary
            )
            .cornerRadius(TalkNoteDesign.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func languageModelCard(model: LanguageModel) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                vm.selectedLanguageModel = model
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.rawValue)
                        .font(TalkNoteDesign.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(vm.selectedLanguageModel == model ? .white : TalkNoteDesign.Colors.textPrimary)
                    
                    Text(model.description)
                        .font(TalkNoteDesign.Typography.caption)
                        .foregroundColor(vm.selectedLanguageModel == model ? .white.opacity(0.8) : TalkNoteDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                if vm.selectedLanguageModel == model {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding(TalkNoteDesign.Spacing.sm)
            .background(
                vm.selectedLanguageModel == model ? 
                TalkNoteDesign.Colors.primaryBlue : 
                TalkNoteDesign.Colors.surfaceSecondary
            )
            .cornerRadius(TalkNoteDesign.CornerRadius.small)
        }
        .buttonStyle(PlainButtonStyle())
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
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                // This is the button that will control the collapsible section
                Button(action: {
                    withAnimation(.spring()) {
                        showingLanguageSettings.toggle()
                    }
                }) {
                    HStack {
                        Label("Language Configuration", systemImage: "globe")
                            .font(TalkNoteDesign.Typography.headline)
                            .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: showingLanguageSettings ? "chevron.up" : "chevron.down")
                            .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to avoid default button styling
                
                // This is the content that will be shown or hidden
                if showingLanguageSettings {
                    VStack(spacing: TalkNoteDesign.Spacing.md) {
                        // Source Language Selection
                        VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                            Text("Source Language (What you speak)")
                                .font(TalkNoteDesign.Typography.callout)
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
                        
                        Divider()
                        
                        // Target Language Selection
                        VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                            Text("Target Language (Translation output)")
                                .font(TalkNoteDesign.Typography.callout)
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
                    .padding(.top, TalkNoteDesign.Spacing.sm) // Add some padding to separate from the button
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
                            
                            Toggle("", isOn: $vm.isMLLearningEnabled)
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
                            
                            Toggle("", isOn: $vm.isAutoDetectEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: TalkNoteDesign.Colors.primaryBlue))
                        }
                        
                        Divider()
                        
                        // Confidence Threshold
                        VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                            HStack {
                                Text("Translation Confidence Threshold")
                                    .font(TalkNoteDesign.Typography.callout)
                                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(vm.confidenceThreshold * 100))%")
                                    .font(TalkNoteDesign.Typography.caption)
                                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(TalkNoteDesign.Colors.surfaceSecondary)
                                    .cornerRadius(4)
                            }
                            
                            HStack {
                                Text("Low")
                                    .font(TalkNoteDesign.Typography.caption)
                                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                                
                                Slider(value: $vm.confidenceThreshold, in: 0.1...1.0, step: 0.05)
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
    
    // MARK: - Model Selection
    
    private var modelSelectionView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                HStack {
                    Label("AI Model Configuration", systemImage: "brain.head.profile")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            showingModelSettings.toggle()
                        }
                    }) {
                        Image(systemName: showingModelSettings ? "chevron.up" : "chevron.down")
                            .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    }
                }
                
                if showingModelSettings {
                    VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                        Text("Choose the best model for your needs. Higher accuracy models may require internet connection.")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        
                        VStack(spacing: TalkNoteDesign.Spacing.sm) {
                            ForEach(TranscriptionModel.allCases) { model in
                                modelSelectionCard(model: model)
                            }
                        }
                        
                        Divider()
                        
                        // Language Model Selection
                        VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                            Text("Language Processing Model")
                                .font(TalkNoteDesign.Typography.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                            
                            ForEach(LanguageModel.allCases) { languageModel in
                                languageModelCard(model: languageModel)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Audio Enhancement Settings
    
    private var audioSettingsView: some View {
        CardView {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                Label("Audio Enhancement", systemImage: "waveform")
                    .font(TalkNoteDesign.Typography.headline)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Text("Samsung-style audio processing for better accuracy")
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                    // Audio Sensitivity
                    VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                        HStack {
                            Text("Microphone Sensitivity")
                                .font(TalkNoteDesign.Typography.callout)
                                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(Int(vm.audioSensitivity * 100))%")
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(TalkNoteDesign.Colors.surfaceSecondary)
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            Text("Low")
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                            
                            Slider(value: $vm.audioSensitivity, in: 0.1...1.0, step: 0.1)
                                .tint(TalkNoteDesign.Colors.primaryBlue)
                            
                            Text("High")
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        }
                        
                        Text("Higher sensitivity catches quiet speech but may pick up background noise")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                    }
                    
                    Divider()
                    
                    // Noise Reduction
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Noise Reduction")
                                .font(TalkNoteDesign.Typography.callout)
                                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                            
                            Text("Reduce background noise for clearer transcription")
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $vm.noiseReduction)
                            .toggleStyle(SwitchToggleStyle(tint: TalkNoteDesign.Colors.primaryBlue))
                    }
                    
                    Divider()
                    
                    // Sound Environment Detection
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Environment Sound Detection")
                                .font(TalkNoteDesign.Typography.callout)
                                .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                            
                            Text("Identify and describe surrounding sounds like Samsung Live Transcribe")
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $vm.soundEnvironmentDetection)
                            .toggleStyle(SwitchToggleStyle(tint: TalkNoteDesign.Colors.primaryBlue))
                    }
                    
                    if vm.soundEnvironmentDetection && !vm.environmentSounds.isEmpty {
                        HStack {
                            Text("Detected Sounds:")
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                            
                            Text(vm.environmentSounds)
                                .font(TalkNoteDesign.Typography.caption)
                                .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                        }
                        .padding(.horizontal, TalkNoteDesign.Spacing.sm)
                        .padding(.vertical, TalkNoteDesign.Spacing.xs)
                        .background(TalkNoteDesign.Colors.primaryBlue.opacity(0.1))
                        .cornerRadius(TalkNoteDesign.CornerRadius.small)
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
                    statisticItem(title: "Live Accuracy", value: vm.dynamicAccuracy.isEmpty ? "Calculating..." : vm.dynamicAccuracy, icon: "target")
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
            "kn": "🇮🇳",
            "ml": "🇮🇳",
            "or": "🇮🇳",
            "pa": "🇮🇳",
            "as": "🇮🇳",
            "ne": "🇳🇵",
            "sd": "🇵🇰",
            "sa": "🇮🇳",
            "es": "🇪🇸",
            "fr": "🇫🇷",
            "de": "🇩🇪",
            "it": "🇮🇹",
            "pt": "🇵🇹",
            "ru": "🇷🇺",
            "ja": "🇯🇵",
            "ko": "🇰🇷",
            "zh": "🇨🇳",
            "ar": "🇸🇦",
            "ur": "🇵🇰",
            "Auto-detect": "🌐",
            "English": "🇺🇸",
            "Spanish": "🇪🇸",
            "French": "🇫🇷",
            "German": "🇩🇪",
            "Italian": "🇮🇹",
            "Portuguese": "🇵🇹",
            "Russian": "🇷🇺",
            "Japanese": "🇯🇵",
            "Korean": "🇰🇷",
            "Chinese": "🇨🇳",
            "Arabic": "🇸🇦",
            "Hindi": "🇮🇳",
            "Urdu": "🇵🇰",
            "Bengali": "🇧🇩",
            "Telugu": "🇮🇳",
            "Marathi": "🇮🇳",
            "Tamil": "🇮🇳",
            "Gujarati": "🇮🇳",
            "Kannada": "🇮🇳",
            "Malayalam": "🇮🇳",
            "Odia": "🇮🇳",
            "Punjabi": "🇮🇳",
            "Assamese": "🇮🇳",
            "Nepali": "🇳🇵",
            "Sindhi": "🇵🇰",
            "Sanskrit": "🇮🇳"
        ]
        return flags[code] ?? "🌐"
    }
}
