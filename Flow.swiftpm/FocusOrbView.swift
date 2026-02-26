import SwiftUI
import SceneKit

// MARK: - Focus Orb View
// Public API preserved for DashboardView compatibility.
// Renders a true 3D interactive globe via SceneKit.

struct FocusOrbView: View {
    let score: Double
    let size: CGFloat
    var isBreathingGuide: Bool = false
    var breathPhase: BreathPhase = .idle

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

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Ambient glowing pulse behind the 3D globe
            // The speed goes from 2.5s calm to a rapid 0.4s heartbeat when overloaded
            let duration: Double = 2.5 - (score / 100.0) * 2.1 
            // The physical scale gets slightly larger when stressed
            let maxScale: CGFloat = 1.05 + CGFloat(score / 100.0) * 0.20 
            let minScale: CGFloat = 0.9 - CGFloat(score / 100.0) * 0.05
            
            // At higher scores, the glow spreads out much further into the background
            let minBlur: CGFloat = size * 0.20
            let maxBlur: CGFloat = size * 0.50
            let currentBlur: CGFloat = minBlur + (maxBlur - minBlur) * CGFloat(score / 100.0)
            
            PhaseAnimator([false, true]) { phase in
                Circle()
                    .fill(FlowColors.glowColor(for: score))
                    .frame(width: size * 0.95, height: size * 0.95)
                    .blur(radius: currentBlur)
                    .scaleEffect(phase ? maxScale : minScale)
                    .opacity(phase ? 0.9 : 0.4)
            } animation: { _ in
                .easeInOut(duration: max(duration, 0.4)) // Prevent duration from ever hitting 0 or negative
            }
            
            GlobeSceneView(score: score)
                // Render larger so the sphere never clips at the square edge.
                .frame(width: size * 1.3, height: size * 1.3)
                .padding(-size * 0.15)
        }
    }
}
