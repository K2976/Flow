import SwiftUI

// MARK: - Session Summary View

struct SessionSummaryView: View {
    @Environment(CognitiveLoadEngine.self) private var engine
    @Environment(SessionManager.self) private var sessionManager
    
    let session: SessionRecord
    
    @State private var appeared = false
    @State private var showNameInput = false
    @State private var sessionName = ""
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Card
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(FlowColors.color(for: 25))
                    
                    Text("Session Complete")
                        .font(FlowTypography.headingFont(size: 20))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Divider()
                    .background(.white.opacity(0.1))
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
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
                VStack(spacing: 8) {
                    Text(ScienceInsights.reflectionLine(for: session))
                        .font(FlowTypography.bodyFont(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Text(ScienceInsights.recoveryCost(for: session))
                        .font(FlowTypography.captionFont(size: 12))
                        .foregroundStyle(.white.opacity(0.3))
                }
                
                // Science insight
                Text(ScienceInsights.insightForState(CognitiveState.from(score: session.endScore)))
                    .font(FlowTypography.captionFont(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                // Name input (shown when Save is tapped)
                if showNameInput {
                    VStack(spacing: 10) {
                        Text("Name this session")
                            .font(FlowTypography.captionFont(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        TextField("e.g. Deep Work, Morning Focus...", text: $sessionName)
                            .font(FlowTypography.bodyFont(size: 14))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
                            )
                            .textFieldStyle(.plain)
                            .focused($isNameFieldFocused)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isNameFieldFocused = true
                                }
                            }
                            .onSubmit {
                                sessionManager.saveSession(name: sessionName, engine: engine)
                            }
                        
                        Button {
                            sessionManager.saveSession(name: sessionName, engine: engine)
                        } label: {
                            Text("Save & Start New")
                                .font(FlowTypography.bodyFont(size: 14))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(FlowColors.color(for: 30).opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    // Buttons
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showNameInput = true
                            }
                        } label: {
                            Text("Save Session")
                                .font(FlowTypography.bodyFont(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            sessionManager.dismissSummary()
                            sessionManager.startNewSession(engine: engine)
                        } label: {
                            Text("New Session")
                                .font(FlowTypography.bodyFont(size: 14))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(FlowColors.color(for: 30).opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(32)
            .frame(width: 380)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .colorScheme(.dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 40, y: 10)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }
    
    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(FlowTypography.labelFont(size: 22))
                .foregroundStyle(.white.opacity(0.9))
                .monospacedDigit()
            
            Text(label)
                .font(FlowTypography.captionFont(size: 11))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
    
    private var formattedDuration: String {
        let duration = session.endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
}
