import SwiftUI

// MARK: - Flow App Entry Point

@main
struct FlowApp: App {
    @State private var engine = CognitiveLoadEngine()
    @State private var sessionManager = SessionManager()
    @State private var simulation = SimulationManager()
    @State private var audio = AudioManager()
    @State private var menuBar = MenuBarManager()
    
    private let haptics = HapticsManager()
    
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showFocusMode = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                hasOnboarded: $hasOnboarded,
                showFocusMode: $showFocusMode,
                haptics: haptics
            )
            .environment(engine)
            .environment(sessionManager)
            .environment(simulation)
            .environment(audio)
            .frame(minWidth: 680, minHeight: 780)
            .preferredColorScheme(.dark)
            .onAppear {
                setupApp()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 820)
    }
    
    private func setupApp() {
        // Start simulation if not interacted
        if hasOnboarded {
            simulation.startSimulation(engine: engine)
        }
        
        // Try to set up menubar (optional — app works without it)
        menuBar.setup(
            engine: engine,
            sessionManager: sessionManager,
            simulation: simulation,
            audio: audio,
            haptics: haptics
        )
    }
}

// MARK: - Content View (Root Router)

struct ContentView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Environment(SimulationManager.self) private var simulation
    
    @Binding var hasOnboarded: Bool
    @Binding var showFocusMode: Bool
    
    let haptics: HapticsManager
    
    var body: some View {
        ZStack {
            if !hasOnboarded {
                OnboardingView(hasOnboarded: $hasOnboarded)
                    .transition(.opacity)
                    .onDisappear {
                        // Start simulation after onboarding
                        simulation.startSimulation(engine: engine)
                    }
            } else if showFocusMode {
                FocusModeView(haptics: haptics, isPresented: $showFocusMode)
                    .transition(.opacity)
            } else {
                DashboardView(haptics: haptics)
                    .transition(.opacity)
            }
        }
        .animation(FlowAnimation.viewTransition, value: hasOnboarded)
        .animation(FlowAnimation.viewTransition, value: showFocusMode)
        // Keyboard shortcuts (local only — sandbox safe)
        .background {
            // Hidden buttons for keyboard shortcuts
            Group {
                Button("") { logMindWandered() }
                    .keyboardShortcut(.space, modifiers: [])
                Button("") { logEvent(.appSwitch) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("") { logEvent(.notification) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("") { logEvent(.mindWandered) }
                    .keyboardShortcut("3", modifiers: .command)
                Button("") { toggleFocusMode() }
                    .keyboardShortcut("f", modifiers: .command)
            }
            .opacity(0)
            .frame(width: 0, height: 0)
        }
    }
    
    private func logMindWandered() {
        simulation.userHasInteracted = true
        engine.logEvent(.mindWandered)
        haptics.playEventFeedback()
    }
    
    private func logEvent(_ event: AttentionEvent) {
        simulation.userHasInteracted = true
        engine.logEvent(event)
        haptics.playEventFeedback()
    }
    
    private func toggleFocusMode() {
        showFocusMode.toggle()
        if showFocusMode {
            simulation.userHasInteracted = true
        }
    }
}
