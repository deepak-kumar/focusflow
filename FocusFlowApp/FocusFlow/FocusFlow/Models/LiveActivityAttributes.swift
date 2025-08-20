import Foundation
import ActivityKit

// MARK: - Shared Live Activity Attributes
// This struct is used by both the main app target and the widget extension

struct Include_Live_ActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}
