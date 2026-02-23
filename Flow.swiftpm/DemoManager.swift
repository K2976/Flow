import Foundation
import SwiftUI

// MARK: - Demo Manager

@MainActor
@Observable
final class DemoManager {
    
    /// Persisted demo mode toggle — defaults to true for judge experience
    var isDemoMode: Bool {
        didSet {
            UserDefaults.standard.set(isDemoMode, forKey: "isDemoMode")
        }
    }
    
    init() {
        // Default to true (demo on) if never set
        if UserDefaults.standard.object(forKey: "isDemoMode") == nil {
            self.isDemoMode = true
        } else {
            self.isDemoMode = UserDefaults.standard.bool(forKey: "isDemoMode")
        }
    }
}
