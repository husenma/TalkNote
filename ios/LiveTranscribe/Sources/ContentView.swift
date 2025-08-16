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
        NavigationView {
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
                .ignoresSafeArea()
                
                VStack(spacing: TalkNoteDesign.Spacing.lg) {
                    // Header with security status
                    headerView
                    
                    // Main transcription area
                    transcriptionAreaView
                        .layoutPriority(1)
                    
                    // Language selection cards
                    languageSelectionView
                    
                    // Main control button
                    microphoneButtonView
                    
                    // Recording indicator
                    if vm.isTranscribing {
                        recordingIndicatorView
                    }
                    
                    Spacer(minLength: TalkNoteDesign.Spacing.md)
                }
                .padding(TalkNoteDesign.Spacing.md)
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            // Check permissions when view appears
            startupPermissionManager.checkInitialPermissions()
            permissionManager.checkCurrentPermissions()
        }
        .onChange(of: startupPermissionManager.allPermissionsGranted) { granted in
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
                    Text("TalkNote")
                        .font(TalkNoteDesign.Typography.largeTitle)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Text("Real-time Translation")
                        .font(TalkNoteDesign.Typography.caption)
                        .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: TalkNoteDesign.Spacing.sm) {
                // Permission status indicator
                Button(action: {
                    if !startupPermissionManager.allPermissionsGranted {
                        startupPermissionManager.showingPermissionScreen = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: startupPermissionManager.allPermissionsGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(startupPermissionManager.allPermissionsGranted ? .green : .orange)
                        Text(startupPermissionManager.allPermissionsGranted ? "Ready to record" : "Permissions needed")
                            .font(TalkNoteDesign.Typography.caption)
                            .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Security status
                Button(action: { showingSecuritySettings = true }) {
                    SecurityStatusView(securityManager: securityManager)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Settings button
                Button(action: { showingLanguageSettings = true }) {
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
                                Text(vm.displayText)
                                    .font(TalkNoteDesign.Typography.body)
                                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                                    .textSelection(.enabled)
                                    .id("transcriptionText")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: vm.displayText) { _ in
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
                    vm.toggle()
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
