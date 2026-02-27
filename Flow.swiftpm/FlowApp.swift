import SwiftUI

// MARK: - Flow App Entry Point

@main
struct FlowApp: App {
    @State private var engine = CognitiveLoadEngine()
    @State private var demoManager = DemoManager()
    @State private var sessionManager: SessionManager
    @State private var simulation = SimulationManager()
    @State private var realDetector = RealEventDetector()
    @State private var audio = AudioManager()
    @State private var menuBar = MenuBarManager()
    
    private let haptics = HapticsManager()
    
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showFocusMode = false
    
    init() {
        let demo = DemoManager()
        _demoManager = State(initialValue: demo)
        _sessionManager = State(initialValue: SessionManager(isDemoMode: demo.isDemoMode))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                hasOnboarded: $hasOnboarded,
                showFocusMode: $showFocusMode,
                haptics: haptics
            )
            .environment(engine)
            .environment(demoManager)
            .environment(sessionManager)
            .environment(simulation)
            .environment(realDetector)
            .environment(audio)
            .frame(minWidth: 680, minHeight: 780)
            .preferredColorScheme(.dark)
            .onAppear {
                setupApp()
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 820)
        #endif
    }
    
    private func setupApp() {
        if hasOnboarded {
            if demoManager.isDemoMode {
                simulation.startSimulation(engine: engine)
            } else {
                realDetector.start(engine: engine)
            }
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
    @Environment(DemoManager.self) private var demoManager
    @Environment(SimulationManager.self) private var simulation
    @Environment(RealEventDetector.self) private var realDetector
    
    @Binding var hasOnboarded: Bool
    @Binding var showFocusMode: Bool
    
    let haptics: HapticsManager
    
    @State private var showLaunchScreen = true
    
    var body: some View {
        ZStack {
            if !hasOnboarded {
                OnboardingView(hasOnboarded: $hasOnboarded)
                    .transition(.opacity)
                    .onDisappear {
                        // Start simulation or real detection after onboarding
                        if demoManager.isDemoMode {
                            simulation.startSimulation(engine: engine)
                        } else {
                            realDetector.start(engine: engine)
                        }
                    }
            } else if showFocusMode {
                FocusModeView(haptics: haptics, isPresented: $showFocusMode)
                    .transition(.opacity)
            } else {
                DashboardView(haptics: haptics)
                    .transition(.opacity)
            }
            
            // Launch loading screen overlay
            if showLaunchScreen && hasOnboarded {
                ColdLoadingView(isPresented: $showLaunchScreen)
                    .transition(.opacity)
                    .zIndex(100)
                    .onAppear {
                        // Auto-dismiss after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showLaunchScreen = false
                            }
                        }
                    }
            }
        }
        .animation(FlowAnimation.viewTransition, value: hasOnboarded)
        .animation(FlowAnimation.viewTransition, value: showFocusMode)
        .animation(.easeOut(duration: 0.5), value: showLaunchScreen)
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
