//
//  AlarmwidgetLiveActivity.swift
//  Alarmwidget
//
//  Created by Sebastian on 2/22/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AlarmwidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AlarmwidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmwidgetAttributes.self) { context in
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

extension AlarmwidgetAttributes {
    fileprivate static var preview: AlarmwidgetAttributes {
        AlarmwidgetAttributes(name: "World")
    }
}

extension AlarmwidgetAttributes.ContentState {
    fileprivate static var smiley: AlarmwidgetAttributes.ContentState {
        AlarmwidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AlarmwidgetAttributes.ContentState {
         AlarmwidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AlarmwidgetAttributes.preview) {
   AlarmwidgetLiveActivity()
} contentStates: {
    AlarmwidgetAttributes.ContentState.smiley
    AlarmwidgetAttributes.ContentState.starEyes
}
