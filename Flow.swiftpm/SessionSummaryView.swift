import SwiftUI

// MARK: - Session Summary View

struct SessionSummaryView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.flowScale) private var s
    
    let session: SessionRecord
    
    @State private var appeared = false
    @State private var showNamePicker = false
    @State private var selectedName: String = ""
    @State private var showColdLoading = false
    @State private var pendingAction: (() -> Void)? = nil
    
    private let presetNames = [
        "Deep Work",
        "Morning Focus",
        "Creative Session",
        "Study Block",
        "Research",
        "Planning",
        "Code Sprint",
        "Writing",
        "Review"
    ]
    
    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Card
            ZStack(alignment: .topLeading) {
                VStack(spacing: 24 * s) {
                // Header
                VStack(spacing: 8 * s) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28 * s))
                        .foregroundStyle(FlowColors.color(for: 25))
                    
                    Text("Session Complete")
                        .font(FlowTypography.headingFont(size: 20 * s))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Divider()
                    .background(.white.opacity(0.1))
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16 * s) {
                    statItem(label: "Duration", value: formattedDuration)
                    statItem(label: "Events", value: "\(session.eventCount)")
                    statItem(label: "Start", value: "\(Int(session.startScore))")
                    statItem(label: "End", value: "\(Int(session.endScore))")
                    statItem(label: "Average", value: "\(Int(session.averageScore))")
                    statItem(label: "Peak", value: "\(Int(session.peakScore))")
                }
                
                Divider()
                    .background(.white.opacity(0.1))
                
                // Reflection
                VStack(spacing: 8 * s) {
                    Text(ScienceInsights.reflectionLine(for: session))
                        .font(FlowTypography.bodyFont(size: 14 * s))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Text(ScienceInsights.recoveryCost(for: session))
                        .font(FlowTypography.captionFont(size: 12 * s))
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                // Science insight
                Text(ScienceInsights.insightForState(CognitiveState.from(score: session.endScore)))
                    .font(FlowTypography.captionFont(size: 12 * s))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8 * s)
                
                if showNamePicker {
                    // Name picker — click to select, then confirm
                    VStack(spacing: 10 * s) {
                        Text("Choose a name for this session")
                            .font(FlowTypography.captionFont(size: 12 * s))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        // Preset name grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8 * s) {
                            ForEach(presetNames, id: \.self) { name in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedName = name
                                    }
                                } label: {
                                    Text(name)
                                        .font(FlowTypography.captionFont(size: 11 * s))
                                        .foregroundStyle(selectedName == name ? .white : .white.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8 * s)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8 * s)
                                                .fill(selectedName == name ?
                                                      FlowColors.color(for: 30).opacity(0.35) :
                                                      .white.opacity(0.06))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8 * s)
                                                .stroke(selectedName == name ?
                                                        FlowColors.color(for: 30).opacity(0.5) :
                                                        .white.opacity(0.1), lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Confirm button
                        Button {
                            let name = selectedName
                            triggerLoadingTransition {
                                sessionManager.saveSession(name: name, engine: engine)
                            }
                        } label: {
                            Text("Save as \"\(selectedName)\"")
                                .font(FlowTypography.bodyFont(size: 13 * s))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10 * s)
                                .background(
                                    RoundedRectangle(cornerRadius: 10 * s)
                                        .fill(FlowColors.color(for: 30).opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10 * s)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // Buttons
                    HStack(spacing: 16 * s) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedName = defaultSessionName
                                showNamePicker = true
                            }
                        } label: {
                            Text("Save Session")
                                .font(FlowTypography.bodyFont(size: 14 * s))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10 * s)
                                .background(
                                    RoundedRectangle(cornerRadius: 10 * s)
                                        .fill(.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10 * s)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            triggerLoadingTransition {
                                sessionManager.dismissSummary()
                                sessionManager.startNewSession(engine: engine)
                            }
                        } label: {
                            Text("New Session")
                                .font(FlowTypography.bodyFont(size: 14 * s))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10 * s)
                                .background(
                                    RoundedRectangle(cornerRadius: 10 * s)
                                        .fill(FlowColors.color(for: 30).opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10 * s)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                }
                
                // Close button
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        sessionManager.dismissSummary()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12 * s, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 28 * s, height: 28 * s)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.08))
                        )
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.06), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(8 * s)
            }
            .padding(32 * s)
            .frame(width: 380 * s)
            .background(
                RoundedRectangle(cornerRadius: 24 * s)
                    .fill(.ultraThinMaterial)
                    .colorScheme(.dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24 * s)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 40 * s, y: 10 * s)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
            
            // Cinematic loading overlay for transitions
            if showColdLoading {
                ColdLoadingView(isPresented: $showColdLoading)
                    .transition(.opacity)
                    .zIndex(200)
            }
        }
        .animation(.easeOut(duration: 0.3), value: showColdLoading)
        .onChange(of: showColdLoading) { _, newValue in
            if !newValue, let action = pendingAction {
                action()
                pendingAction = nil
            }
        }
    }
    
    private func triggerLoadingTransition(action: @escaping () -> Void) {
        pendingAction = action
        withAnimation(.easeOut(duration: 0.3)) {
            showColdLoading = true
        }
        // Dismiss after animation plays
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showColdLoading = false
            }
        }
    }
    
    private var defaultSessionName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Session – \(formatter.string(from: session.startTime))"
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4 * s) {
            Text(value)
                .font(FlowTypography.labelFont(size: 22 * s))
                .foregroundStyle(.white.opacity(0.9))
                .monospacedDigit()
            
            Text(label)
                .font(FlowTypography.captionFont(size: 11 * s))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
    
    private var formattedDuration: String {
        let duration = session.realDuration ?? session.endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}
