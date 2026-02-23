import Foundation
import SwiftUI

#if os(macOS)
import AppKit
import CoreGraphics
#endif

// MARK: - Real Event Detector (Normal Mode Only)

@MainActor
@Observable
final class RealEventDetector {
    
    private(set) var isActive: Bool = false
    
    // App switch tracking
    private var appSwitchTimestamps: [Date] = []
    private let rapidSwitchThreshold: Int = 3
    private let rapidSwitchWindow: TimeInterval = 30
    
    // Idle tracking
    private var idleTimer: Timer?
    private let idleThreshold: TimeInterval = 60 // seconds of inactivity
    private var hasLoggedIdleSinceLastActivity: Bool = false
    
    #if os(macOS)
    private var workspaceObserver: NSObjectProtocol?
    #endif
    
    // MARK: - Start / Stop
    
    func start(engine: CognitiveLoadEngine) {
        guard !isActive else { return }
        isActive = true
        hasLoggedIdleSinceLastActivity = false
        appSwitchTimestamps.removeAll()
        
        #if os(macOS)
        startAppSwitchObserver(engine: engine)
        startIdlePolling(engine: engine)
        #endif
    }
    
    func stop() {
        isActive = false
        
        #if os(macOS)
        if let observer = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            workspaceObserver = nil
        }
        #endif
        
        idleTimer?.invalidate()
        idleTimer = nil
        appSwitchTimestamps.removeAll()
    }
    
    // MARK: - macOS Observers
    
    #if os(macOS)
    
    private func startAppSwitchObserver(engine: CognitiveLoadEngine) {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppSwitch(engine: engine)
            }
        }
    }
    
    private func handleAppSwitch(engine: CognitiveLoadEngine) {
        guard isActive else { return }
        
        let now = Date()
        
        // Log the app switch event
        engine.logEvent(.appSwitch)
        
        // Track for rapid switching detection
        appSwitchTimestamps.append(now)
        
        // Clean old timestamps
        let cutoff = now.addingTimeInterval(-rapidSwitchWindow)
        appSwitchTimestamps = appSwitchTimestamps.filter { $0 > cutoff }
        
        // Check rapid switching
        if appSwitchTimestamps.count >= rapidSwitchThreshold {
            engine.logEvent(.rapidSwitch)
            appSwitchTimestamps.removeAll() // Reset after triggering
        }
        
        // User is active — reset idle tracking
        hasLoggedIdleSinceLastActivity = false
    }
    
    private func startIdlePolling(engine: CognitiveLoadEngine) {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdle(engine: engine)
            }
        }
    }
    
    private func checkIdle(engine: CognitiveLoadEngine) {
        guard isActive, !hasLoggedIdleSinceLastActivity else { return }
        
        // CGEventSource.secondsSinceLastEventType works without special entitlements
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )
        let keyboardIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )
        
        let totalIdle = min(idleTime, keyboardIdle)
        
        if totalIdle >= idleThreshold {
            engine.logEvent(.idle)
            hasLoggedIdleSinceLastActivity = true
        }
    }
    
    #endif
}
