import Foundation

// MARK: - Science Insights

@MainActor
struct ScienceInsights {
    
    static let insights: [String] = [
        "Every task switch costs 23 minutes of refocusing time — even small ones.",
        "Your prefrontal cortex can only hold 4 ± 1 items in working memory.",
        "Attention is not a resource you spend — it's a muscle you train.",
        "The brain uses 20% of your energy. Cognitive overload burns through glucose reserves.",
        "Multitasking reduces productivity by up to 40%, according to the American Psychological Association.",
        "Flow state requires about 15 minutes of undisturbed focus to enter.",
        "Notification sounds trigger cortisol release even when you don't check them.",
        "Deep breathing activates the parasympathetic nervous system within 30 seconds.",
        "The default mode network activates during rest — it's when insights emerge.",
        "Sleep consolidates working memory. Overloaded days need recovery sleep.",
        "Attention restoration theory suggests nature exposure resets cognitive fatigue.",
        "The Zeigarnik Effect: unfinished tasks occupy working memory until resolved.",
        "Micro-breaks of 40 seconds can restore 50% of cognitive performance.",
        "Your brain processes 11 million bits per second but is only conscious of 50.",
        "Focused attention meditation strengthens the anterior cingulate cortex.",
    ]
    
    private static var usedIndices: Set<Int> = []
    
    static func randomInsight() -> String {
        if usedIndices.count >= insights.count {
            usedIndices.removeAll()
        }
        
        var index: Int
        repeat {
            index = Int.random(in: 0..<insights.count)
        } while usedIndices.contains(index)
        
        usedIndices.insert(index)
        return insights[index]
    }
    
    static func insightForState(_ state: CognitiveState) -> String {
        switch state {
        case .calm, .focused:
            return insights.filter { $0.contains("Flow") || $0.contains("focus") || $0.contains("rest") }.randomElement() ?? randomInsight()
        case .moderate:
            return insights.filter { $0.contains("working memory") || $0.contains("switch") }.randomElement() ?? randomInsight()
        case .high, .overloaded:
            return insights.filter { $0.contains("overload") || $0.contains("break") || $0.contains("breathing") }.randomElement() ?? randomInsight()
        }
    }
    
    /// Returns a soft emotional reflection based on session end state
    static func reflectionLine(for record: SessionRecord) -> String {
        let state = CognitiveState.from(score: record.endScore)
        switch state {
        case .calm:
            return "You ended in stillness. That's rare and valuable."
        case .focused:
            return "A balanced session. Your attention held."
        case .moderate:
            return "Some turbulence, but you stayed aware."
        case .high:
            return "It was a demanding session. You showed up anyway."
        case .overloaded:
            return "Heavy session. Rest is not optional — it's necessary."
        }
    }
    
    /// Estimated recovery cost in minutes
    static func recoveryCost(for record: SessionRecord) -> String {
        let peak = record.peakScore
        if peak < 50 {
            return "~2 min recovery"
        } else if peak < 70 {
            return "~5 min recovery"
        } else if peak < 85 {
            return "~10 min recovery"
        } else {
            return "~15+ min recovery"
        }
    }
}
