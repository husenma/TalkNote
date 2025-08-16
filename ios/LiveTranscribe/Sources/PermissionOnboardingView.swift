import SwiftUI

struct PermissionOnboardingView: View {
    @ObservedObject var permissionManager: StartupPermissionManager
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    TalkNoteDesign.Colors.primaryBlue.opacity(0.1),
                    TalkNoteDesign.Colors.accentGreen.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: TalkNoteDesign.Spacing.xl) {
                Spacer()
                
                // App Icon & Title
                VStack(spacing: TalkNoteDesign.Spacing.lg) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 80))
                        .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    
                    Text("Welcome to TalkNote")
                        .font(TalkNoteDesign.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Real-time voice translation made simple")
                        .font(TalkNoteDesign.Typography.body)
                        .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Permission Steps
                VStack(spacing: TalkNoteDesign.Spacing.lg) {
                    permissionStepView
                    
                    if permissionManager.permissionStep == .completed {
                        completedView
                    } else {
                        actionButtons
                    }
                }
                
                Spacer()
                
                // Privacy Note
                Text("Your privacy is protected. Audio is only used for translation and never stored.")
                    .font(TalkNoteDesign.Typography.caption)
                    .foregroundColor(TalkNoteDesign.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, TalkNoteDesign.Spacing.lg)
            }
            .padding(TalkNoteDesign.Spacing.lg)
        }
    }
    
    private var permissionStepView: some View {
        CardView(padding: TalkNoteDesign.Spacing.lg) {
            VStack(spacing: TalkNoteDesign.Spacing.md) {
                // Progress indicator
                HStack(spacing: TalkNoteDesign.Spacing.sm) {
                    ForEach(Array(StartupPermissionManager.PermissionStep.allCases.enumerated()), id: \.offset) { index, step in
                        Circle()
                            .fill(stepColor(for: step))
                            .frame(width: 12, height: 12)
                            .scaleEffect(permissionManager.permissionStep == step ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: permissionManager.permissionStep)
                        
                        if index < StartupPermissionManager.PermissionStep.allCases.count - 1 {
                            Rectangle()
                                .fill(stepColor(for: step))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.bottom, TalkNoteDesign.Spacing.sm)
                
                // Current step
                VStack(spacing: TalkNoteDesign.Spacing.sm) {
                    Image(systemName: permissionManager.permissionStep.icon)
                        .font(.system(size: 48))
                        .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
                    
                    Text(permissionManager.permissionStep.title)
                        .font(TalkNoteDesign.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(TalkNoteDesign.Colors.textPrimary)
                    
                    Text(permissionManager.permissionStep.description)
                        .font(TalkNoteDesign.Typography.body)
                        .foregroundColor(TalkNoteDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: TalkNoteDesign.Spacing.md) {
            Button(action: {
                Task {
                    await permissionManager.requestCurrentPermission()
                }
            }) {
                HStack {
                    Text("Grant Permission")
                        .font(TalkNoteDesign.Typography.headline)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(TalkNoteDesign.Spacing.md)
                .background(TalkNoteDesign.Colors.primaryBlue)
                .cornerRadius(TalkNoteDesign.CornerRadius.medium)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button("Open Settings") {
                permissionManager.openSettings()
            }
            .font(TalkNoteDesign.Typography.callout)
            .foregroundColor(TalkNoteDesign.Colors.primaryBlue)
        }
    }
    
    private var completedView: some View {
        VStack(spacing: TalkNoteDesign.Spacing.md) {
            Button("Start Using TalkNote") {
                permissionManager.showingPermissionScreen = false
            }
            .font(TalkNoteDesign.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(TalkNoteDesign.Spacing.md)
            .background(TalkNoteDesign.Colors.accentGreen)
            .cornerRadius(TalkNoteDesign.CornerRadius.medium)
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func stepColor(for step: StartupPermissionManager.PermissionStep) -> Color {
        let currentIndex = StartupPermissionManager.PermissionStep.allCases.firstIndex(of: permissionManager.permissionStep) ?? 0
        let stepIndex = StartupPermissionManager.PermissionStep.allCases.firstIndex(of: step) ?? 0
        
        if stepIndex <= currentIndex {
            return TalkNoteDesign.Colors.accentGreen
        } else {
            return TalkNoteDesign.Colors.textTertiary.opacity(0.3)
        }
    }
}
