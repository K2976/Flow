import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Environment(\.flowScale) private var s
    @Binding var hasOnboarded: Bool
    
    @State private var showText = false
    @State private var showPrompt = false
    @State private var showOrbs = false
    @State private var selectedLevel: Int? = nil
    @State private var isTransitioning = false
    @State private var showColdLoading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !showColdLoading {
                VStack(spacing: 40 * s) {
                    Spacer()
                    
                    // Orb — always alive
                    FocusOrbView(score: [10.0, 30, 50, 70, 90][(selectedLevel ?? 1) - 1], size: 200 * s)
                    
                    // Text
                    if showText {
                        Text("Your attention has a shape.\nFlow shows it to you.")
                            .font(FlowTypography.labelFont(size: 20 * s))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                    
                    // Prompt
                    if showPrompt {
                        VStack(spacing: 24 * s) {
                            Text("How focused are you right now?")
                                .font(FlowTypography.bodyFont(size: 16 * s))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            // 5 glowing orb fragments
                            HStack(spacing: 20 * s) {
                                ForEach(1...5, id: \.self) { level in
                                    orbFragment(level: level)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    Spacer()
                }
                .padding(40 * s)
                .transition(.opacity)
            }
            
            // Cinematic loading overlay
            if showColdLoading {
                ColdLoadingView(isPresented: $showColdLoading)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .animation(.easeOut(duration: 0.4), value: showColdLoading)
        .onAppear {
            // Staggered reveal — interaction available within 5 seconds
            withAnimation(.easeIn(duration: 1.0)) {
                showText = true
            }
            withAnimation(.easeIn(duration: 0.8).delay(1.5)) {
                showPrompt = true
            }
            withAnimation(.easeIn(duration: 0.6).delay(2.0)) {
                showOrbs = true
            }
        }
    }
    
    @ViewBuilder
    private func orbFragment(level: Int) -> some View {
        let isSelected = selectedLevel == level
        let levelLabels = ["Calm", "Relaxed", "Moderate", "Elevated", "Overloaded"]
        let levelScores: [Double] = [10, 30, 50, 70, 90]
        let score = levelScores[level - 1]
        let label = levelLabels[level - 1]
        let color = FlowColors.color(for: score)
        
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedLevel = level
            }
            
            // Set initial score and show loading screen
            engine.setInitialScore(score)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showColdLoading = true
                }
                // Transition to main app after loading
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    hasOnboarded = true
                }
            }
        } label: {
            VStack(spacing: 8 * s) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color, color.opacity(0.4)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20 * s
                        )
                    )
                    .frame(width: (isSelected ? 48 : 40) * s, height: (isSelected ? 48 : 40) * s)
                    .shadow(color: color.opacity(isSelected ? 0.8 : 0.3), radius: (isSelected ? 15 : 5) * s)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(isSelected ? 0.4 : 0), lineWidth: 2)
                    )
                
                Text(label)
                    .font(FlowTypography.captionFont(size: 10 * s))
                    .foregroundStyle(.white.opacity(isSelected ? 0.9 : 0.4))
            }
        }
        .buttonStyle(.plain)
        .opacity(showOrbs ? 1 : 0)
        .animation(.easeIn(duration: 0.4).delay(Double(level) * 0.1), value: showOrbs)
    }
}
