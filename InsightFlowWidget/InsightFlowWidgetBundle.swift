//
//  InsightFlowWidgetBundle.swift
//  InsightFlowWidget
//
//  Created by Simon Luthe on 10.12.25.
//

import WidgetKit
import SwiftUI

@main
struct InsightFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        InsightFlowWidget()
        InsightFlowWidgetLiveActivity()
    }
}
