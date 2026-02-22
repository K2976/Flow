import SwiftUI

// MARK: - Focus Orb View

struct FocusOrbView: View {
    let score: Double
    let size: CGFloat
    var isBreathingGuide: Bool = false
    var breathPhase: BreathPhase = .idle
    
    @State private var time: Double = 0
    
    enum BreathPhase {
        case idle, breatheIn, hold, breatheOut
        
        var label: String {
            switch self {
            case .idle: return ""
            case .breatheIn: return "Breathe In"
            case .hold: return "Hold"
            case .breatheOut: return "Breathe Out"
            }
        }
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0)) { timeline in
            Canvas { context, canvasSize in
                let now = timeline.date.timeIntervalSinceReferenceDate
                drawOrb(context: context, size: canvasSize, time: now)
            }
            .frame(width: size, height: size)
        }
    }
    
    // MARK: - Drawing
    
    private func drawOrb(context: GraphicsContext, size: CGSize, time: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let normalizedScore = min(max(score, 0), 100) / 100.0
        
        // Base radius with score-based scaling
        let baseRadius = min(size.width, size.height) * 0.22
        let scoreScale = 1.0 + normalizedScore * 0.25
        
        // Breathing pulse
        let pulseSpeed = 0.5 + normalizedScore * 1.5 // 0.5Hz calm → 2Hz overloaded
        let pulseAmount = 0.03 + normalizedScore * 0.07
        let pulse = sin(time * pulseSpeed * .pi) * pulseAmount
        
        let radius = baseRadius * scoreScale * (1.0 + pulse)
        
        // Colors
        let orbColor = FlowColors.color(for: score)
        let glowColor = FlowColors.glowColor(for: score)
        
        // Draw outer glow layers
        let glowIntensity = 0.1 + normalizedScore * 0.25
        for i in stride(from: 4, through: 1, by: -1) {
            let glowRadius = radius * (1.0 + Double(i) * 0.15)
            let alpha = glowIntensity / Double(i)
            
            var glowPath: Path
            if normalizedScore > 0.7 {
                // Organic distortion at high load
                glowPath = distortedCircle(center: center, radius: glowRadius, time: time, intensity: normalizedScore)
            } else {
                glowPath = Path(ellipseIn: CGRect(
                    x: center.x - glowRadius,
                    y: center.y - glowRadius,
                    width: glowRadius * 2,
                    height: glowRadius * 2
                ))
            }
            
            context.fill(glowPath, with: .color(glowColor.opacity(alpha)))
        }
        
        // Draw main orb
        let orbPath: Path
        if normalizedScore > 0.7 {
            orbPath = distortedCircle(center: center, radius: radius, time: time, intensity: normalizedScore)
        } else {
            orbPath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
        
        // Gradient fill
        let gradient = Gradient(colors: [
            orbColor.opacity(0.9),
            orbColor,
            orbColor.opacity(0.7)
        ])
        
        context.fill(orbPath, with: .radialGradient(
            gradient,
            center: CGPoint(x: center.x - radius * 0.2, y: center.y - radius * 0.2),
            startRadius: 0,
            endRadius: radius * 1.2
        ))
        
        // Inner highlight
        let highlightRadius = radius * 0.4
        let highlightCenter = CGPoint(x: center.x - radius * 0.15, y: center.y - radius * 0.2)
        let highlightPath = Path(ellipseIn: CGRect(
            x: highlightCenter.x - highlightRadius,
            y: highlightCenter.y - highlightRadius,
            width: highlightRadius * 2,
            height: highlightRadius * 1.5
        ))
        context.fill(highlightPath, with: .color(.white.opacity(0.08 + pulse * 0.05)))
        
        // Particles at high load
        if normalizedScore > 0.6 {
            drawParticles(context: context, center: center, radius: radius, time: time, intensity: normalizedScore)
        }
    }
    
    // MARK: - Distortion
    
    private func distortedCircle(center: CGPoint, radius: Double, time: Double, intensity: Double) -> Path {
        var path = Path()
        let distortionAmount = (intensity - 0.7) * 15.0 // 0 at 70%, up to ~4.5 at 100%
        let segments = 64
        
        for i in 0...segments {
            let angle = (Double(i) / Double(segments)) * 2.0 * .pi
            
            // Multiple frequency noise
            let noise1 = sin(angle * 3 + time * 1.2) * distortionAmount
            let noise2 = sin(angle * 5 + time * 0.8) * distortionAmount * 0.5
            let noise3 = cos(angle * 7 + time * 1.5) * distortionAmount * 0.3
            
            let r = radius + noise1 + noise2 + noise3
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
    
    // MARK: - Particles
    
    private func drawParticles(context: GraphicsContext, center: CGPoint, radius: Double, time: Double, intensity: Double) {
        let particleCount = Int((intensity - 0.6) * 25) // 0–10 particles
        let color = FlowColors.color(for: score)
        
        for i in 0..<particleCount {
            let seed = Double(i) * 2.399 // Golden angle offset
            let particleTime = time * 0.3 + seed
            
            // Spiral outward
            let angle = seed + particleTime * 0.5
            let distance = radius * (1.1 + (sin(particleTime * 0.7) + 1) * 0.4)
            
            let x = center.x + cos(angle) * distance
            let y = center.y + sin(angle) * distance
            
            let particleSize = 2.0 + sin(particleTime * 2) * 1.5
            let alpha = max(0, 0.6 - (distance - radius) / (radius * 0.8))
            
            let particlePath = Path(ellipseIn: CGRect(
                x: x - particleSize / 2,
                y: y - particleSize / 2,
                width: particleSize,
                height: particleSize
            ))
            
            context.fill(particlePath, with: .color(color.opacity(alpha)))
        }
    }
}


