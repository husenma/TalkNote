import SwiftUI
import Speech
import AVFoundation

struct ContentView: View {
    @StateObject private var vm = TranscriptionViewModel()
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var permissionManager = PermissionManager()
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
            // Initial permission check
            permissionManager.checkCurrentPermissions()
            
            // Only request permissions if they haven't been requested yet
            if !permissionManager.hasRequestedPermissions && 
               (permissionManager.microphonePermission == .undetermined || 
                permissionManager.speechPermission == .notDetermined) {
                Task {
                    // Add a small delay to ensure UI is fully loaded
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await permissionManager.requestAllPermissions()
                }
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
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: TalkNoteDesign.Spacing.xs) {
                Text("TalkNote")
                    .font(TalkNoteDesign.Typography.largeTitle)
                    .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                
                Text("Real-time Translation")
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: TalkNoteDesign.Spacing.sm) {
                // Permission status indicator
                Button(action: {
                    if permissionManager.permissionsDenied {
                        permissionManager.openAppSettings()
                    } else if !permissionManager.allPermissionsGranted {
                        Task {
                            await permissionManager.requestAllPermissions()
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: permissionManager.allPermissionsGranted ? "checkmark.circle.fill" : 
                                         permissionManager.permissionsDenied ? "exclamationmark.triangle.fill" : "circle")
                            .foregroundColor(permissionManager.allPermissionsGranted ? .green : 
                                           permissionManager.permissionsDenied ? .orange : .gray)
                        Text(permissionManager.shortPermissionStatus)
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
                                    Image(systemName: !permissionManager.allPermissionsGranted ? "lock.circle" : "mic.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(TalkNoteDesign.Colors.textTertiary)
                                    
                                    Text(!permissionManager.allPermissionsGranted ? 
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
                if permissionManager.allPermissionsGranted {
                    vm.toggle()
                } else if permissionManager.permissionsDenied {
                    permissionManager.openAppSettings()
                } else {
                    Task {
                        await permissionManager.requestAllPermissions()
                    }
                }
            }, isDisabled: !permissionManager.allPermissionsGranted)
            
            Text(permissionManager.permissionsDenied ? 
                 "Tap to open Settings" :
                 !permissionManager.allPermissionsGranted ? 
                 "Tap to grant permissions" :
                 vm.isTranscribing ? "Tap to stop recording" : "Tap to start recording")
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
