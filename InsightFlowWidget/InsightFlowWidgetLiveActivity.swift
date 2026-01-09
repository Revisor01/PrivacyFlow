//
//  PrivacyFlowWidgetLiveActivity.swift
//  PrivacyFlowWidget
//
//  Created by Simon Luthe on 10.12.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PrivacyFlowWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PrivacyFlowWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrivacyFlowWidgetAttributes.self) { context in
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

extension PrivacyFlowWidgetAttributes {
    fileprivate static var preview: PrivacyFlowWidgetAttributes {
        PrivacyFlowWidgetAttributes(name: "World")
    }
}

extension PrivacyFlowWidgetAttributes.ContentState {
    fileprivate static var smiley: PrivacyFlowWidgetAttributes.ContentState {
        PrivacyFlowWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PrivacyFlowWidgetAttributes.ContentState {
         PrivacyFlowWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PrivacyFlowWidgetAttributes.preview) {
   PrivacyFlowWidgetLiveActivity()
} contentStates: {
    PrivacyFlowWidgetAttributes.ContentState.smiley
    PrivacyFlowWidgetAttributes.ContentState.starEyes
}
