import SwiftUI

// MARK: - Recovery View (Smart Reset)

struct RecoveryView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Binding var isPresented: Bool
    
    @State private var showColdLoading = false
    
    var body: some View {
        ZStack {
            if !showColdLoading {
                // Dark scrim
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isPresented = false }
                    }
                
                // Pre-recovery message
                VStack(spacing: 16) {
                    Image(systemName: "wind")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange.opacity(0.7))
                    
                    Text("Your mind is overloaded")
                        .font(FlowTypography.labelFont(size: 18))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text("Take a moment. Nothing is urgent enough to burn out for.")
                        .font(FlowTypography.bodyFont(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                    
                    Button {
                        startRecovery()
                    } label: {
                        Text("Reset Attention")
                            .font(FlowTypography.labelFont(size: 15))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(FlowColors.color(for: 30).opacity(0.5))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .colorScheme(.dark)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Cinematic loading overlay during reset
            if showColdLoading {
                ColdLoadingView(isPresented: $showColdLoading)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(FlowAnimation.viewTransition, value: showColdLoading)
        .onChange(of: showColdLoading) { _, newValue in
            if !newValue {
                // Loading screen dismissed — close recovery
                isPresented = false
            }
        }
    }
    
    private func startRecovery() {
        // Trigger score decay
        engine.triggerAcceleratedDecay(amount: max(engine.score - 20, 0), duration: 2)
        
        // Show cinematic loading screen
        withAnimation(FlowAnimation.viewTransition) {
            showColdLoading = true
        }
        
        // Complete after decay finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            engine.markReset()
            engine.setScore(20)
            
            // Dismiss loading screen (which then dismisses recovery)
            withAnimation(.easeOut(duration: 0.5)) {
                showColdLoading = false
            }
        }
    }
}
