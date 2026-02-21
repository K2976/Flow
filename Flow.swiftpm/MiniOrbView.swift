import SwiftUI

// MARK: - Mini Orb View (Menubar / Popover)

struct MiniOrbView: View {
    let score: Double
    let size: CGFloat
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
            Canvas { context, canvasSize in
                let now = timeline.date.timeIntervalSinceReferenceDate
                drawMiniOrb(context: context, size: canvasSize, time: now)
            }
            .frame(width: size, height: size)
        }
    }
    
    private func drawMiniOrb(context: GraphicsContext, size: CGSize, time: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let normalizedScore = min(max(score, 0), 100) / 100.0
        let radius = min(size.width, size.height) * 0.38
        
        // Gentle pulse
        let pulse = sin(time * (0.8 + normalizedScore) * .pi) * 0.04
        let r = radius * (1.0 + pulse)
        
        let color = FlowColors.color(for: score)
        
        // Glow
        let glowPath = Path(ellipseIn: CGRect(
            x: center.x - r * 1.3,
            y: center.y - r * 1.3,
            width: r * 2.6,
            height: r * 2.6
        ))
        context.fill(glowPath, with: .color(color.opacity(0.15)))
        
        // Orb
        let orbPath = Path(ellipseIn: CGRect(
            x: center.x - r,
            y: center.y - r,
            width: r * 2,
            height: r * 2
        ))
        
        let gradient = Gradient(colors: [
            color.opacity(0.8),
            color,
            color.opacity(0.6)
        ])
        context.fill(orbPath, with: .radialGradient(
            gradient,
            center: CGPoint(x: center.x - r * 0.15, y: center.y - r * 0.15),
            startRadius: 0,
            endRadius: r
        ))
    }
}
