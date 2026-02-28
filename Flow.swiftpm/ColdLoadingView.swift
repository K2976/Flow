import SwiftUI

// MARK: - Cold Light Formation Loading Screen

struct ColdLoadingView: View {
    @Binding var isPresented: Bool
    @Environment(\.flowScale) private var s
    
    // Animation phases
    @State private var glowOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.6
    @State private var textOpacity: Double = 0
    @State private var textBlur: CGFloat = 8
    @State private var sweepOffset: CGFloat = -200
    @State private var sweepOpacity: Double = 0
    @State private var fadeOut: Double = 1.0
    
    // Phase 5: Netflix rush-forward
    @State private var rushScale: CGFloat = 1.0
    @State private var rushOpacity: Double = 1.0
    
    // Particles
    @State private var particles: [ColdParticle] = []
    @State private var particleOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Pure near-black background
            Color(red: 0.04, green: 0.04, blue: 0.05)
                .ignoresSafeArea()
            
            // Phase 1: Central radial glow
            RadialGradient(
                colors: [
                    Color(hue: 0.72, saturation: 0.45, brightness: 0.35).opacity(glowOpacity),
                    Color(hue: 0.68, saturation: 0.3, brightness: 0.2).opacity(glowOpacity * 0.5),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 200 * s
            )
            .scaleEffect(glowScale)
            .ignoresSafeArea()
            
            // Phase 2: Particle convergence
            ForEach(particles) { particle in
                Circle()
                    .fill(.white.opacity(particle.opacity * particleOpacity))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
            }
            .scaleEffect(rushScale)
            .opacity(rushOpacity)
            
            // Phase 3 + 5: App name reveal then rush forward
            ZStack {
                Text("FLOW")
                    .font(.system(size: 42 * s, weight: .bold, design: .rounded))
                    .tracking(12 * s)
                    .foregroundStyle(.white.opacity(textOpacity * 0.88))
                    .blur(radius: textBlur)
                
                // Phase 4: Light sweep across text
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(sweepOpacity * 0.15),
                                Color(hue: 0.6, saturation: 0.2, brightness: 1.0).opacity(sweepOpacity * 0.08),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60 * s, height: 50 * s)
                    .offset(x: sweepOffset * s)
                    .mask(
                        Text("FLOW")
                            .font(.system(size: 42 * s, weight: .bold, design: .rounded))
                            .tracking(12 * s)
                    )
            }
            .scaleEffect(rushScale)
            .opacity(rushOpacity)
        }
        .opacity(fadeOut)
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    // MARK: - Particle Generation
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 120...280)
            return ColdParticle(
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 1.2...2.5),
                opacity: Double.random(in: 0.10...0.22)
            )
        }
    }
    
    // MARK: - Animation Sequencing
    
    private func startAnimation() {
        // Phase 1: Glow emerges (0 → 600ms)
        withAnimation(.easeOut(duration: 0.6)) {
            glowOpacity = 0.18
            glowScale = 1.0
        }
        
        // Phase 2: Particles drift inward (400ms → 1400ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 1.0)) {
                particleOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                for i in particles.indices {
                    particles[i].x *= 0.15
                    particles[i].y *= 0.15
                }
            }
        }
        
        // Phase 3: Text reveal (600ms → 1500ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.9)) {
                textOpacity = 1.0
                textBlur = 0
            }
        }
        
        // Phase 4: Light sweep (1000ms → 1600ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sweepOpacity = 1.0
            withAnimation(.easeInOut(duration: 0.6)) {
                sweepOffset = 200
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.2)) {
                    sweepOpacity = 0
                }
            }
        }
        
        // Phase 5: Netflix rush-forward (1600ms → 2200ms)
        // Text + particles scale up dramatically as if flying toward the viewer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeIn(duration: 0.6)) {
                rushScale = 4.0
                rushOpacity = 0
            }
            // Fade everything else out simultaneously
            withAnimation(.easeIn(duration: 0.5)) {
                glowOpacity = 0
                particleOpacity = 0
            }
        }
    }
    
    // MARK: - Dismiss
    
    func dismiss() {
        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0
            textOpacity = 0
            particleOpacity = 0
            fadeOut = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}

// MARK: - Cold Particle Model

struct ColdParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
}
