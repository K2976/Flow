import SwiftUI

// MARK: - Recovery View (Smart Reset)

struct RecoveryView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Binding var isPresented: Bool
    
    @State private var showColdLoading = false
    @State private var scoreCheckTimer: Timer?
    
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
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(FlowAnimation.viewTransition, value: showColdLoading)
        .onChange(of: showColdLoading) { _, newValue in
            if !newValue {
                scoreCheckTimer?.invalidate()
                scoreCheckTimer = nil
                isPresented = false
            }
        }
    }
    
    private func startRecovery() {
        let baseScore: Double = 20
        let currentScore = engine.score
        let scoreToDrop = max(currentScore - baseScore, 0)
        
        // Scale decay duration based on how much score needs to drop
        // Higher score = longer decay (roughly 0.05s per point)
        let decayDuration = max(scoreToDrop * 0.05, 2.0)
        
        // Trigger score decay
        engine.triggerAcceleratedDecay(amount: scoreToDrop, duration: decayDuration)
        
        // Show cinematic loading screen
        withAnimation(FlowAnimation.viewTransition) {
            showColdLoading = true
        }
        
        // Poll engine score — dismiss only when score reaches baseline + 1 extra second
        scoreCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            Task { @MainActor in
                if engine.score <= baseScore + 1 {
                    // Score reached baseline — wait 1 more second then dismiss
                    scoreCheckTimer?.invalidate()
                    scoreCheckTimer = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        engine.markReset()
                        engine.setScore(baseScore)
                        
                        withAnimation(.easeOut(duration: 0.5)) {
                            showColdLoading = false
                        }
                    }
                }
            }
        }
    }
}
