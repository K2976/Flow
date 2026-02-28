import SwiftUI

// MARK: - History Strip View (7-Day)

struct HistoryStripView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.flowScale) private var s
    
    @State private var selectedDay: DaySummary?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8 * s) {
            Text("LAST 7 DAYS")
                .font(FlowTypography.captionFont(size: 10 * s))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(1.5)
            
            HStack(spacing: 6 * s) {
                ForEach(sessionManager.weekHistory) { day in
                    daySquare(day)
                }
            }
            
            // Day detail popover
            if let day = selectedDay {
                dayDetail(day)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(FlowAnimation.viewTransition, value: selectedDay?.id)
    }
    
    private func daySquare(_ day: DaySummary) -> some View {
        let isSelected = selectedDay?.id == day.id
        let hasData = day.eventCount > 0 || day.averageScore > 0
        let color = hasData ? FlowColors.pastelColor(for: day.averageScore) : Color.white
        
        return Button {
            guard hasData else { return }
            withAnimation {
                selectedDay = selectedDay?.id == day.id ? nil : day
            }
        } label: {
            VStack(spacing: 5 * s) {
                RoundedRectangle(cornerRadius: 10 * s)
                    .fill(hasData
                          ? color.opacity(isSelected ? 1.0 : 0.85)
                          : Color.white.opacity(0.06))
                    .frame(height: 44 * s)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10 * s)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .opacity(hasData ? 1 : 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10 * s)
                            .stroke(.white.opacity(isSelected ? 0.5 : 0.15), lineWidth: isSelected ? 1.5 : 1.0)
                    )
                    .shadow(color: .clear, radius: 0)
                
                Text(dayLabel(day.date))
                    .font(.system(size: 12 * s, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(hasData ? (isSelected ? 0.9 : 0.6) : 0.2))
            }
        }
        .buttonStyle(.plain)
    }
    
    private func dayDetail(_ day: DaySummary) -> some View {
        let sessions = sessionManager.savedSessions(for: day.date)
        
        return VStack(alignment: .leading, spacing: 8 * s) {
            // Day overview
            HStack(spacing: 16 * s) {
                VStack(alignment: .leading, spacing: 2 * s) {
                    Text(fullDayLabel(day.date))
                        .font(FlowTypography.bodyFont(size: 13 * s))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("Avg: \(Int(day.averageScore)) • Peak: \(Int(day.peakScore))")
                        .font(FlowTypography.captionFont(size: 11 * s))
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2 * s) {
                    Text("\(day.eventCount) events")
                        .font(FlowTypography.captionFont(size: 11 * s))
                        .foregroundStyle(.white.opacity(0.4))
                    
                    Text("\(Int(day.totalMinutes))m tracked")
                        .font(FlowTypography.captionFont(size: 11 * s))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            
            // Saved sessions for this day
            if !sessions.isEmpty {
                Divider()
                    .background(.white.opacity(0.08))
                
                ForEach(sessions) { session in
                    HStack(spacing: 10 * s) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10 * s))
                            .foregroundStyle(FlowColors.color(for: session.averageScore).opacity(0.7))
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(session.name ?? "Session")
                                .font(FlowTypography.bodyFont(size: 12 * s))
                                .foregroundStyle(.white.opacity(0.6))
                            
                            let duration = Int(session.endTime.timeIntervalSince(session.startTime))
                            let mins = duration / 60
                            let secs = duration % 60
                            Text("\(mins)m \(secs)s • Avg: \(Int(session.averageScore)) • Peak: \(Int(session.peakScore))")
                                .font(FlowTypography.captionFont(size: 10 * s))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        
                        Spacer()
                        
                        Text("\(session.eventCount) events")
                            .font(FlowTypography.captionFont(size: 10 * s))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.vertical, 4 * s)
                }
            }
        }
        .padding(.horizontal, 12 * s)
        .padding(.vertical, 8 * s)
        .background(
            RoundedRectangle(cornerRadius: 10 * s)
                .fill(.white.opacity(0.04))
        )
    }
    
    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func fullDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
