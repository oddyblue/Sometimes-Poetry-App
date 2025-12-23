//
//  SometimesWidget.swift
//  SometimesWidget
//
//  The Anti-Widget: An app that doesn't want your attention.
//  Empty by default. Shows first line briefly after delivery. Fades back to empty.
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data (App Group)

/// Shared container for widget data
/// App Group: group.com.sometimes.app
struct WidgetData {
    static let appGroupID = "group.com.sometimes.app"
    static let suiteName = "group.com.sometimes.app"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // Keys
    private static let firstLineKey = "widget_first_line"
    private static let poetKey = "widget_poet"
    private static let deliveredAtKey = "widget_delivered_at"
    private static let wasOpenedKey = "widget_was_opened"

    /// The first line of the current poem (if any)
    static var firstLine: String? {
        get { sharedDefaults?.string(forKey: firstLineKey) }
        set { sharedDefaults?.set(newValue, forKey: firstLineKey) }
    }

    /// The poet of the current poem
    static var poet: String? {
        get { sharedDefaults?.string(forKey: poetKey) }
        set { sharedDefaults?.set(newValue, forKey: poetKey) }
    }

    /// When the poem was delivered
    static var deliveredAt: Date? {
        get { sharedDefaults?.object(forKey: deliveredAtKey) as? Date }
        set { sharedDefaults?.set(newValue, forKey: deliveredAtKey) }
    }

    /// Whether the user opened the app after delivery
    static var wasOpened: Bool {
        get { sharedDefaults?.bool(forKey: wasOpenedKey) ?? false }
        set { sharedDefaults?.set(newValue, forKey: wasOpenedKey) }
    }

    /// Clear all widget data (return to empty state)
    static func clear() {
        sharedDefaults?.removeObject(forKey: firstLineKey)
        sharedDefaults?.removeObject(forKey: poetKey)
        sharedDefaults?.removeObject(forKey: deliveredAtKey)
        sharedDefaults?.removeObject(forKey: wasOpenedKey)
    }

    /// Set new poem data
    static func setPoem(firstLine: String, poet: String) {
        self.firstLine = firstLine
        self.poet = poet
        self.deliveredAt = Date()
        self.wasOpened = false
    }
}

// MARK: - Widget State

enum WidgetState {
    case empty          // Default: just "Sometimes"
    case active         // After delivery: first line visible
    case read           // After opened: small dot, then empty

    static func current() -> WidgetState {
        guard let deliveredAt = WidgetData.deliveredAt,
              WidgetData.firstLine != nil else {
            return .empty
        }

        let hoursSinceDelivery = Date().timeIntervalSince(deliveredAt) / 3600

        // After 4 hours, return to empty
        if hoursSinceDelivery > 4 {
            return .empty
        }

        // If opened, show read state briefly then empty
        if WidgetData.wasOpened {
            return hoursSinceDelivery > 1 ? .empty : .read
        }

        return .active
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PoemEntry {
        PoemEntry(date: Date(), state: .empty, firstLine: nil, poet: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PoemEntry) -> ()) {
        let state = WidgetState.current()
        let entry = PoemEntry(
            date: Date(),
            state: state,
            firstLine: WidgetData.firstLine,
            poet: WidgetData.poet
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let now = Date()
        let state = WidgetState.current()

        let entry = PoemEntry(
            date: now,
            state: state,
            firstLine: WidgetData.firstLine,
            poet: WidgetData.poet
        )

        // Schedule next refresh based on state
        let nextRefresh: Date
        switch state {
        case .empty:
            // Refresh every hour when empty (in case poem arrives)
            nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        case .active:
            // Refresh in 4 hours to return to empty
            if let deliveredAt = WidgetData.deliveredAt {
                nextRefresh = deliveredAt.addingTimeInterval(4 * 3600)
            } else {
                nextRefresh = Calendar.current.date(byAdding: .hour, value: 4, to: now)!
            }
        case .read:
            // Refresh in 1 hour to return to empty
            nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct PoemEntry: TimelineEntry {
    let date: Date
    let state: WidgetState
    let firstLine: String?
    let poet: String?
}

// MARK: - Widget Views

struct SometimesWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private var backgroundColor: Color {
        Color(red: 0.98, green: 0.98, blue: 0.97)
    }

    private var textColor: Color {
        Color(red: 0.1, green: 0.1, blue: 0.1)
    }

    private var secondaryColor: Color {
        Color(red: 0.42, green: 0.42, blue: 0.42)
    }

    private var accentColor: Color {
        Color(red: 0.49, green: 0.55, blue: 0.49)
    }

    var body: some View {
        Group {
            switch entry.state {
            case .empty:
                emptyView
            case .active:
                activeView
            case .read:
                readView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State (Default)

    private var emptyView: some View {
        VStack {
            Spacer()
            Text("Sometimes")
                .font(.system(size: family == .systemSmall ? 16 : 20, weight: .medium, design: .serif))
                .foregroundColor(secondaryColor.opacity(0.6))
            Spacer()
        }
    }

    // MARK: - Active State (Poem Delivered)

    private var activeView: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 12) {
            if family != .systemSmall, let poet = entry.poet {
                Text(poet)
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundColor(secondaryColor)
                    .italic()
            }

            if let firstLine = entry.firstLine {
                Text(firstLine)
                    .font(.system(size: family == .systemSmall ? 14 : 16, weight: .regular, design: .serif))
                    .foregroundColor(textColor)
                    .lineLimit(family == .systemSmall ? 3 : 4)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            HStack {
                Spacer()
                Text("Sometimes")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.5))
            }
        }
        .padding(family == .systemSmall ? 12 : 16)
    }

    // MARK: - Read State (Opened, then fading)

    private var readView: some View {
        VStack {
            Spacer()
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 8, height: 8)
            Spacer()
        }
    }
}

// MARK: - Widget Configuration

struct SometimesWidget: Widget {
    let kind: String = "SometimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SometimesWidgetEntryView(entry: entry)
                    .containerBackground(Color(red: 0.98, green: 0.98, blue: 0.97), for: .widget)
            } else {
                SometimesWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color(red: 0.98, green: 0.98, blue: 0.97))
            }
        }
        .configurationDisplayName("Sometimes")
        .description("A poem arrives. Sometimes.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    SometimesWidget()
} timeline: {
    PoemEntry(date: .now, state: .empty, firstLine: nil, poet: nil)
    PoemEntry(date: .now, state: .active, firstLine: "I wandered lonely as a cloud", poet: "William Wordsworth")
    PoemEntry(date: .now, state: .read, firstLine: nil, poet: nil)
}

#Preview(as: .systemMedium) {
    SometimesWidget()
} timeline: {
    PoemEntry(date: .now, state: .active, firstLine: "I wandered lonely as a cloud", poet: "William Wordsworth")
}
