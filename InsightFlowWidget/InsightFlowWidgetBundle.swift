//
//  PrivacyFlowWidgetBundle.swift
//  PrivacyFlowWidget
//
//  Created by Simon Luthe on 10.12.25.
//

import WidgetKit
import SwiftUI

@main
struct PrivacyFlowWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrivacyFlowWidget()
        PrivacyFlowWidgetLiveActivity()
    }
}
