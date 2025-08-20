import Foundation
import ActivityKit

// MARK: - Shared Live Activity Attributes
// This struct is used by both the main app target and the widget extension

struct Include_Live_ActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var phase: String // "Focus", "Short Break", "Long Break"
        var remainingTime: TimeInterval // in seconds
        var progress: Double // 0.0 to 1.0
        var isRunning: Bool
    }

    // Fixed non-changing properties about your activity go here!
    var sessionTitle: String // e.g. "Pomodoro Session"
}