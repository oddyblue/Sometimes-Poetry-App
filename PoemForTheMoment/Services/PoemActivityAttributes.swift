// PoemActivityAttributes.swift
// Live Activity support for poem delivery (requires Widget Extension target)
//
// To enable Live Activities:
// 1. In Xcode: File -> New -> Target -> Widget Extension
// 2. Name it "PoemWidget" and check "Include Live Activity"
// 3. Copy PoemLiveActivityView code into the widget bundle
// 4. Add "NSSupportsLiveActivities" = YES to main app's Info.plist

import Foundation
import ActivityKit

struct PoemActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var poemTitle: String
        var poet: String
        var teaser: String
        var deliveredAt: Date
    }

    var poemID: String
}
