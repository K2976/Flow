import SwiftUI

// MARK: - Focus Mode View

struct FocusModeView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Environment(SessionManager.self) private var sessionManager
    @Environment(AudioManager.self) private var audio
    @Environment(\.flowScale) private var s
    
    let haptics: HapticsManager
    @Binding var isPresented: Bool
    
    @State private var breathPhase: BreathPhaseState = .breatheIn
    @State private var breathProgress: Double = 0
    @State private var cycleCount: Int = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var showBreathText = true
    @State private var orbScale: CGFloat = 0.85
    @State private var timerActive = true
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    enum BreathPhaseState {
        case breatheIn, hold, breatheOut
        
        var label: String {
            switch self {
            case .breatheIn: return "Breathe In"
            case .hold: return "Hold"
            case .breatheOut: return "Breathe Out"
            }
        }
        
        var duration: Double {
            switch self {
            case .breatheIn: return FlowAnimation.breatheIn
            case .hold: return FlowAnimation.breatheHold
            case .breatheOut: return FlowAnimation.breatheOut
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.92)
                .ignoresSafeArea()
            
            VStack(spacing: 30 * s) {
                Spacer()
                
                // Breathing orb
                ZStack {
                    // Timer ring
                    Circle()
                        .stroke(.white.opacity(0.06), lineWidth: 2)
                        .frame(width: 280 * s, height: 280 * s)
                    
                    Circle()
                        .trim(from: 0, to: min(elapsedTime / (5 * 60), 1.0)) // 5 min max
                        .stroke(
                            FlowColors.color(for: engine.animatedScore).opacity(0.4),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 280 * s, height: 280 * s)
                        .rotationEffect(.degrees(-90))
                    
                    FocusOrbView(score: max(engine.animatedScore - 20, 5), size: 250 * s)
                        .scaleEffect(orbScale)
                }
                
                // Breathe text
                if showBreathText {
                    Text(breathPhase.label)
                        .font(FlowTypography.labelFont(size: 22 * s))
                        .foregroundStyle(.white.opacity(0.6))
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.8), value: breathPhase)
                }
                
                // Cycle count
                Text("Cycle \(cycleCount + 1)")
                    .font(FlowTypography.captionFont(size: 12 * s))
                    .foregroundStyle(.white.opacity(0.25))
                
                Spacer()
                
                // Log Distraction button
                Button {
                    engine.logEvent(.mindWandered)
                    haptics.playEventFeedback()
                } label: {
                    HStack(spacing: 8 * s) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 14 * s))
                        Text("Log Distraction")
                            .font(FlowTypography.bodyFont(size: 14 * s))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20 * s)
                    .padding(.vertical, 10 * s)
                    .background(
                        Capsule().fill(.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                
                // End Focus button
                Button {
                    endFocusMode()
                } label: {
                    Text("End Focus")
                        .font(FlowTypography.captionFont(size: 12 * s))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24 * s)
            }
            .padding(40 * s)
        }
        .onReceive(timer) { _ in
            guard timerActive else { return }
            elapsedTime += 0.05
            updateBreathing()
        }
        .onAppear {
            engine.isFocusMode = true
            audio.setFocusMode(true)
            startBreathCycle()
        }
    }
    
    // MARK: - Breathing Logic
    
    private func updateBreathing() {
        breathProgress += 0.05
        
        if breathProgress >= breathPhase.duration {
            breathProgress = 0
            advancePhase()
        }
        
        // Update orb scale based on phase
        let phaseProgress = breathProgress / breathPhase.duration
        switch breathPhase {
        case .breatheIn:
            withAnimation(.linear(duration: 0.05)) {
                orbScale = 0.85 + CGFloat(phaseProgress) * 0.2
            }
        case .hold:
            orbScale = 1.05
        case .breatheOut:
            withAnimation(.linear(duration: 0.05)) {
                orbScale = 1.05 - CGFloat(phaseProgress) * 0.2
            }
        }
    }
    
    private func advancePhase() {
        switch breathPhase {
        case .breatheIn:
            breathPhase = .hold
            haptics.playBreathingHaptic()
        case .hold:
            breathPhase = .breatheOut
        case .breatheOut:
            breathPhase = .breatheIn
            cycleCount += 1
            haptics.playBreathingHaptic()
        }
        
        // Text fade
        withAnimation(.easeInOut(duration: 0.3)) {
            showBreathText = false
        }
        withAnimation(.easeInOut(duration: 0.3).delay(0.2)) {
            showBreathText = true
        }
    }
    
    private func startBreathCycle() {
        breathPhase = .breatheIn
        breathProgress = 0
        orbScale = 0.85
    }
    
    private func endFocusMode() {
        timerActive = false
        engine.isFocusMode = false
        audio.setFocusMode(false)
        audio.playCompletionChime()
        haptics.playCompletionHaptic()
        
        withAnimation(FlowAnimation.viewTransition) {
            isPresented = false
        }
        
        // End session to show summary
        sessionManager.endSession(engine: engine)
    }
}
