import Foundation
import CoreHaptics

// MARK: - Haptics Manager

@MainActor
final class HapticsManager {
    
    private var engine: CHHapticEngine?
    private var isSupported: Bool = false
    
    init() {
        setupHaptics()
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isSupported = false
            return
        }
        
        do {
            let engine = try CHHapticEngine()
            engine.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
                    self?.isSupported = false
                }
            }
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    do {
                        try self?.engine?.start()
                    } catch {
                        self?.isSupported = false
                    }
                }
            }
            try engine.start()
            self.engine = engine
            self.isSupported = true
        } catch {
            isSupported = false
        }
    }
    
    func playEventFeedback() {
        guard isSupported, let engine = engine else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silent failure
        }
    }
    
    func playBreathingHaptic() {
        guard isSupported, let engine = engine else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 2.0)
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silent failure
        }
    }
    
    func playCompletionHaptic() {
        guard isSupported, let engine = engine else { return }
        
        do {
            let events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                    ],
                    relativeTime: 0.15
                )
            ]
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Silent failure
        }
    }
}
