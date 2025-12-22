// ArchiveView.swift
// Clean, minimal library of received poems

import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var appState: AppState
    @State private var poems: [DeliveredPoem] = []
    @State private var showFavoritesOnly = false
    @State private var navigationPath = NavigationPath()
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    // Cached formatter to avoid recreation
    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    // Group poems by month
    var groupedPoems: [(month: Date, poems: [DeliveredPoem])] {
        let filtered = showFavoritesOnly ? poems.filter { $0.isFavorite } : poems
        let grouped = Dictionary(grouping: filtered) { (poem) -> Date in
            let components = Calendar.current.dateComponents([.year, .month], from: poem.deliveredAt)
            return Calendar.current.date(from: components) ?? Date()
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (month: $0.key, poems: $0.value.sorted { $0.deliveredAt > $1.deliveredAt }) }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if poems.isEmpty {
                    EmptyArchiveView()
                } else if showFavoritesOnly && groupedPoems.isEmpty {
                    EmptyFavoritesView()
                } else {
                    poemList
                }
            }
            .background(Color.poemBackground)
            .navigationTitle("Poems")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: DeliveredPoem.self) { delivered in
                PoemDetailView(delivered: delivered)
            }
            .adaptiveToolbarStyle()
            .toolbar {
                if !poems.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(reduceMotion ? .none : .easeInOut(duration: 0.2)) {
                                showFavoritesOnly.toggle()
                            }
                        } label: {
                            Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                .foregroundColor(showFavoritesOnly ? .poemAccent : .poemSecondary)
                        }
                        .ensureMinimumTouchTarget()
                        .accessibilityLabel(showFavoritesOnly ? "Show all poems" : "Show favorites only")
                        .accessibilityHint("Double tap to \(showFavoritesOnly ? "show all poems" : "filter to favorites only")")
                    }
                }
            }
        }
        .task {
            loadPoems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .poemDelivered)) { _ in
            // Refresh when a new poem is delivered
            loadPoems()
        }
        .onChange(of: appState.pendingDeepLinkPoemID) { _, poemID in
            guard let poemID = poemID else { return }
            // Refresh poems first to ensure the new poem is loaded
            loadPoems()
            if let delivered = appState.poemStore.findDeliveredPoem(byPoemID: poemID) {
                navigationPath.append(delivered)
            }
            appState.pendingDeepLinkPoemID = nil
        }
    }

    private var poemList: some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                ForEach(groupedPoems, id: \.month) { group in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Self.monthFormatter.string(from: group.month))
                            .font(.custom("Georgia-Italic", size: 22))
                            .foregroundColor(.poemText)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        ForEach(group.poems) { delivered in
                            NavigationLink(value: delivered) {
                                ArchiveCard(delivered: delivered)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                        }
                    }
                }

                // Bottom spacing
                Color.clear.frame(height: 40)
            }
            .padding(.top, 16)
        }
    }

    @MainActor
    private func loadPoems() {
        poems = appState.poemStore.getDeliveredPoems()
    }
}

// MARK: - Archive Card (iOS 26 Glass + Legacy)

struct ArchiveCard: View {
    let delivered: DeliveredPoem
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Title & Poet
            VStack(alignment: .leading, spacing: 8) {
                AdaptiveHStack(spacing: 12) {
                    Text(delivered.poem.title)
                        .font(.custom("Georgia", size: titleFontSize))
                        .fontWeight(.medium)
                        .foregroundColor(.poemText)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                        .multilineTextAlignment(.leading)

                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer()
                    }

                    if delivered.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.poemAccent)
                            .accessibilityLabel("Favorite")
                    }
                }

                Text(delivered.poem.poet)
                    .font(.custom("Georgia-Italic", size: poetFontSize))
                    .foregroundColor(.poemSecondary)
            }

            // Context Footer
            VStack(alignment: .leading, spacing: 12) {
                Rectangle()
                    .fill(Color.poemDivider)
                    .frame(height: 1)

                HStack {
                    Text(formatContext(delivered))
                        .font(.system(size: contextFontSize, weight: .medium))
                        .foregroundColor(.poemAccentAccessible)
                        .textCase(.lowercase)

                    Spacer()
                }
            }
        }
        .padding(20)
        .background(AdaptiveCardBackground(cornerRadius: cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(delivered.poem.title) by \(delivered.poem.poet)")
        .accessibilityHint("Double tap to read the full poem")
        .accessibilityAddTraits(delivered.isFavorite ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Dynamic Type Responsive Sizes

    private var titleFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 16
        case .medium, .large: return 18
        case .xLarge, .xxLarge: return 20
        default: return 22
        }
    }

    private var poetFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 14
        case .medium, .large: return 16
        default: return 18
        }
    }

    private var contextFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 12
        case .medium, .large: return 13
        default: return 14
        }
    }

    private var cardCornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            return 16 // Liquid Glass style
        }
        return 12 // iOS 18 style
    }
    
    private func formatContext(_ delivered: DeliveredPoem) -> String {
        let date = delivered.deliveredAt
        let weekday = date.formatted(Date.FormatStyle().weekday(.wide))
        let time = getTimeOfDay(date: date)
        
        var context = "\(weekday) \(time)"
        if let weather = delivered.context.weather {
            context += " · \(weather.rawValue)"
        }
        return context
    }
    
    private func getTimeOfDay(date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        if hour < 12 { return "morning" }
        if hour < 17 { return "afternoon" }
        return "evening"
    }
}

// MARK: - Empty State

struct EmptyArchiveView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Your first poem is on its way.")
                .font(.custom("Georgia", size: 24))
                .foregroundColor(.poemText)
                .multilineTextAlignment(.center)

            Text("When it arrives, you'll find\nit here.")
                .font(.custom("Georgia", size: 17))
                .foregroundColor(.poemSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("No favorites yet.")
                .font(.custom("Georgia", size: 24))
                .foregroundColor(.poemText)

            Text("Tap the heart on any poem\nto save it here.")
                .font(.custom("Georgia", size: 17))
                .foregroundColor(.poemSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    ArchiveView()
        .environmentObject(AppState())
}
