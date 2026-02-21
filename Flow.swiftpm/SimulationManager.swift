import Foundation
import SwiftUI

// MARK: - Simulation Manager

@MainActor
@Observable
final class SimulationManager {
    
    private var simulationTimer: Timer?
    private(set) var isSimulating: Bool = false
    private var eventCount: Int = 0
    private let maxAutoEvents: Int = 12
    
    // Track if user has interacted meaningfully
    var userHasInteracted: Bool = false {
        didSet {
            if userHasInteracted {
                fadeOutSimulation()
            }
        }
    }
    
    func startSimulation(engine: CognitiveLoadEngine) {
        guard !userHasInteracted else { return }
        isSimulating = true
        eventCount = 0
        
        // Inject events every 12–18 seconds
        scheduleNextEvent(engine: engine)
    }
    
    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulating = false
    }
    
    private func scheduleNextEvent(engine: CognitiveLoadEngine) {
        let delay = Double.random(in: 12...18)
        simulationTimer?.invalidate()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.injectEvent(engine: engine)
            }
        }
    }
    
    private func injectEvent(engine: CognitiveLoadEngine) {
        guard isSimulating, !userHasInteracted, eventCount < maxAutoEvents else {
            stopSimulation()
            return
        }
        
        // Pick a random event type
        let events: [AttentionEvent] = [.appSwitch, .notification, .mindWandered, .notification, .appSwitch]
        let event = events[eventCount % events.count]
        
        engine.logEvent(event)
        eventCount += 1
        
        // Schedule next
        scheduleNextEvent(engine: engine)
    }
    
    private func fadeOutSimulation() {
        // Gradually stop — let current timer finish, then stop
        simulationTimer?.invalidate()
        simulationTimer = nil
        isSimulating = false
    }
}
