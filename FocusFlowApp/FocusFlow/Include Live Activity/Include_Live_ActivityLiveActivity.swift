//
//  Include_Live_ActivityLiveActivity.swift
//  Include Live Activity
//
//  Created by deepak kumar on 20/08/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Include_Live_ActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Include_Live_ActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Include_Live_ActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Include_Live_ActivityAttributes {
    fileprivate static var preview: Include_Live_ActivityAttributes {
        Include_Live_ActivityAttributes(name: "World")
    }
}

extension Include_Live_ActivityAttributes.ContentState {
    fileprivate static var smiley: Include_Live_ActivityAttributes.ContentState {
        Include_Live_ActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Include_Live_ActivityAttributes.ContentState {
         Include_Live_ActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Include_Live_ActivityAttributes.preview) {
   Include_Live_ActivityLiveActivity()
} contentStates: {
    Include_Live_ActivityAttributes.ContentState.smiley
    Include_Live_ActivityAttributes.ContentState.starEyes
}
