import Foundation

// MARK: - Attention Event Types

enum AttentionEvent: String, CaseIterable, Identifiable {
    case appSwitch = "App Switch"
    case notification = "Notification"
    case mindWandered = "Mind Wandered"
    
    var id: String { rawValue }
    
    var loadIncrease: Double {
        switch self {
        case .appSwitch: return 8
        case .notification: return 6
        case .mindWandered: return 5
        }
    }
    
    var symbol: String {
        switch self {
        case .appSwitch: return "rectangle.on.rectangle"
        case .notification: return "bell.fill"
        case .mindWandered: return "cloud.fill"
        }
    }
    
    var shortcutLabel: String {
        switch self {
        case .appSwitch: return "⌘1"
        case .notification: return "⌘2"
        case .mindWandered: return "Space"
        }
    }
}

// MARK: - Event Record

struct AttentionEventRecord: Identifiable {
    let id = UUID()
    let event: AttentionEvent
    let timestamp: Date
    let scoreAfter: Double
}

// MARK: - History Snapshot

struct LoadSnapshot: Identifiable {
    let id = UUID()
    let timestamp: Date
    let score: Double
}

// MARK: - Day Summary

struct DaySummary: Identifiable {
    let id = UUID()
    let date: Date
    let averageScore: Double
    let peakScore: Double
    let eventCount: Int
    let totalMinutes: Double
}

// MARK: - Session Record

struct SessionRecord: Identifiable {
    let id = UUID()
    var name: String?
    let startTime: Date
    let endTime: Date
    let startScore: Double
    let endScore: Double
    let averageScore: Double
    let peakScore: Double
    let eventCount: Int
    let events: [AttentionEventRecord]
}
