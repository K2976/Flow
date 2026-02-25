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

    var body: some View {
        GlobeSceneView(score: score)
            // Render larger so the sphere never clips at the square edge.
            .frame(width: size * 1.3, height: size * 1.3)
            .padding(-size * 0.15)
    }
}
