import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @StateObject private var vm = TranscriptionViewModel()
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var permissionManager = PermissionManager()
    @StateObject private var startupPermissionManager = StartupPermissionManager()
    @State private var showingLanguageSettings = false
    @State private var showingSecuritySettings = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    TalkNoteDesign.Colors.surface,
                    TalkNoteDesign.Colors.surfaceSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all, edges: .all)
            
            VStack(spacing: TalkNoteDesign.Spacing.lg) {
                // Header with security status
                headerView
                    .padding(.top, TalkNoteDesign.Spacing.xxl) // More top padding since no nav bar
                
                // Main transcription area
                transcriptionAreaView
                    .layoutPriority(1)
                
                // Language selection cards
                languageSelectionView
                
                // Main control button
                microphoneButtonView
                    .padding(.bottom, TalkNoteDesign.Spacing.md)
                
                // Recording indicator
                if vm.isTranscribing {
                    recordingIndicatorView
                }
                
                Spacer(minLength: TalkNoteDesign.Spacing.md)
            }
            .padding(TalkNoteDesign.Spacing.md)
        }
        .ignoresSafeArea(.all, edges: .all)
        .statusBarHidden()
        .onAppear {
            // Check permissions when view appears
            startupPermissionManager.checkInitialPermissions()
            permissionManager.checkCurrentPermissions()
        }
        .onChange(of: startupPermissionManager.allPermissionsGranted) { _, granted in
            if granted {
                // Refresh permission manager when startup permissions are granted
                permissionManager.checkCurrentPermissions()
            }
        }
        .alert("Permissions Required", isPresented: $permissionManager.showingPermissionAlert) {
            Button("Open Settings") {
                permissionManager.openAppSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let explanation = permissionManager.showPermissionExplanation()
            Text(explanation.message)
        }
        .sheet(isPresented: $showingLanguageSettings) {
            LanguageSettingsView(vm: vm)
        }
        .sheet(isPresented: $showingSecuritySettings) {
            SecuritySettingsView(securityManager: securityManager)
        }
        .fullScreenCover(isPresented: $startupPermissionManager.showingPermissionScreen) {
            PermissionOnboardingView(permissionManager: startupPermissionManager)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            // Logo and title section
            HStack(spacing: TalkNoteDesign.Spacing.sm) {
                // App logo
                if let logoImage = UIImage(named: "logo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Fallback icon if logo doesn't load
                    Image(systemName: "message.fill")
                        .font(.system(size: 24))
                        .foregroundColor(TalkNoteDesign.Colors.accent)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.xs) {
                    Text(vm.isTranscribing ? "Listening..." : "TalkNote")
                        .font(TalkNoteDesign.Typography.largeTitle)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Text(vm.isTranscribing ? vm.currentLanguage : "Real-time Translation")
                        .font(TalkNoteDesign.Typography.caption)
                        .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: TalkNoteDesign.Spacing.sm) {
                // Settings dropdown button with security inside
                Menu {
                    Button(action: { showingLanguageSettings = true }) {
                        Label("Language & AI Settings", systemImage: "globe")
                    }
                    
                    Button(action: { showingSecuritySettings = true }) {
                        Label("Security Settings", systemImage: "lock")
                    }
                    
                    if !startupPermissionManager.allPermissionsGranted {
                        Button(action: { startupPermissionManager.showingPermissionScreen = true }) {
                            Label("Grant Permissions", systemImage: "exclamationmark.triangle")
                        }
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
    
    // MARK: - Transcription Area
    
    private var transcriptionAreaView: some View {
        CardView(padding: TalkNoteDesign.Spacing.lg) {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.md) {
                HStack {
                    Label("Live Transcription", systemImage: "text.bubble")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    if vm.isTranscribing {
                        WaveFormView(isActive: vm.isTranscribing)
                    }
                }
                
                ScrollView {
                    ScrollViewReader { proxy in
                        VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.sm) {
                            if vm.displayText.isEmpty {
                                VStack(spacing: TalkNoteDesign.Spacing.md) {
                                    Image(systemName: !startupPermissionManager.allPermissionsGranted ? "lock.circle" : "mic.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(TalkNoteDesign.Colors.textTertiary)
                                    
                                    Text(!startupPermissionManager.allPermissionsGranted ? 
                                         "Grant microphone and speech permissions to start" :
                                         "Tap the microphone to start speaking")
                                        .font(TalkNoteDesign.Typography.body)
                                        .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, minHeight: 120)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(vm.displayText)
                                        .font(TalkNoteDesign.Typography.body)
                                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                                        .textSelection(.enabled)
                                        .padding(12)
                                        .background(TalkNoteDesign.Colors.surfaceSecondary)
                                        .cornerRadius(8)
                                        .id("transcriptionText")
                                    
                                    // Character count indicator
                                    HStack {
                                        Text("\(vm.displayText.count) characters")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        if vm.isTranscribing {
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 8, height: 8)
                                                Text("LIVE")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Debug status section - show model and enhanced info
                            if vm.isTranscribing {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("🎙️ \(vm.debugStatus)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 4) {
                                            if vm.isMLLearningEnabled {
                                                Text("🧠 AI")
                                                    .font(.caption2)
                                                    .foregroundColor(.purple)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(Color.purple.opacity(0.1))
                                                    .cornerRadius(3)
                                            }
                                            
                                            if vm.noiseReduction {
                                                Text("🔇 NR")
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 1)
                                                    .background(Color.green.opacity(0.1))
                                                    .cornerRadius(3)
                                            }
                                        }
                                    }
                                    
                                    // Model information
                                    HStack {
                                        Text("📱 Model: \(vm.selectedTranscriptionModel.rawValue)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("🎯 \(vm.dynamicAccuracy)")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                    
                                    // Environment sounds
                                    if vm.soundEnvironmentDetection && !vm.environmentSounds.isEmpty {
                                        HStack {
                                            Text("🔊 Environment:")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(vm.environmentSounds)
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    if !vm.predictionReasoning.isEmpty {
                                        Text("🔍 \(vm.predictionReasoning)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    HStack {
                                        Text("🗣️ From: \(vm.detectedLanguage != "Unknown" ? vm.detectedLanguage : vm.sourceLanguage)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        if vm.detectedLanguage != "Unknown" && vm.detectedLanguage != "English" {
                                            Text("→ 🇺🇸 \(vm.targetLanguage)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.horizontal, 8)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(6)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: vm.displayText) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("transcriptionText", anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    // MARK: - Language Selection
    
    private var languageSelectionView: some View {
        HStack(spacing: TalkNoteDesign.Spacing.md) {
            LanguagePickerCard(
                selectedLanguage: $vm.sourceLanguage,
                supportedLanguages: vm.supportedSources,
                title: "From Language"
            )
            
            // Swap button
            Button(action: swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    .padding(TalkNoteDesign.Spacing.sm)
                    .background(TalkNoteDesign.Colors.surfaceSecondary)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            
            LanguagePickerCard(
                selectedLanguage: $vm.targetLanguage,
                supportedLanguages: vm.supportedTargets,
                title: "To Language"
            )
        }
    }
    
    // MARK: - Microphone Button
    
    private var microphoneButtonView: some View {
        VStack(spacing: TalkNoteDesign.Spacing.sm) {
            MicrophoneButton(isRecording: $vm.isTranscribing, action: {
                if startupPermissionManager.allPermissionsGranted && permissionManager.allPermissionsGranted {
                    Task {
                        if vm.isTranscribing {
                            await vm.stop()
                        } else {
                            await vm.start()
                        }
                    }
                } else {
                    startupPermissionManager.showingPermissionScreen = true
                }
            }, isDisabled: !startupPermissionManager.allPermissionsGranted)
            
            Text(startupPermissionManager.allPermissionsGranted ? 
                 (vm.isTranscribing ? "Tap to stop recording" : "Tap to start recording") :
                 "Tap to grant permissions")
                .font(TalkNoteDesign.Typography.caption)
                .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Recording Indicator
    
    private var recordingIndicatorView: some View {
        HStack(spacing: TalkNoteDesign.Spacing.sm) {
            Circle()
                .fill(TalkNoteDesign.Colors.accentRed)
                .frame(width: 8, height: 8)
                .scaleEffect(vm.isTranscribing ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: vm.isTranscribing)
            
            Text("Recording...")
                .font(TalkNoteDesign.Typography.caption)
                .foregroundColor(TalkNoteDesign.Colors.accentRed)
        }
        .padding(.horizontal, TalkNoteDesign.Spacing.md)
        .padding(.vertical, TalkNoteDesign.Spacing.xs)
        .background(TalkNoteDesign.Colors.accentRed.opacity(0.1))
        .cornerRadius(TalkNoteDesign.CornerRadius.large)
    }
    
    // MARK: - Helper Methods
    
    private func swapLanguages() {
        withAnimation(.spring()) {
            let temp = vm.sourceLanguage
            vm.sourceLanguage = vm.targetLanguage
            vm.targetLanguage = temp
        }
    }
}

#Preview {
    ContentView()
}
