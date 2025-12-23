// PoemStore.swift
// Manages poem corpus, delivery history, and favorites
// Uses SwiftData for persistent storage of delivered poems

import Foundation
import SwiftData
import OSLog
import WidgetKit

private let logger = Logger(subsystem: "com.sometimes.app", category: "PoemStore")

// MARK: - Widget Data Manager

/// Manages widget data via App Group
/// Requires App Group capability: group.com.sometimes.app
enum WidgetDataManager {
    private static let suiteName = "group.com.sometimes.app"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// Update widget with new poem data
    static func poemDelivered(firstLine: String, poet: String) {
        sharedDefaults?.set(firstLine, forKey: "widget_first_line")
        sharedDefaults?.set(poet, forKey: "widget_poet")
        sharedDefaults?.set(Date(), forKey: "widget_delivered_at")
        sharedDefaults?.set(false, forKey: "widget_was_opened")
        WidgetCenter.shared.reloadTimelines(ofKind: "SometimesWidget")
    }

    /// Mark widget as opened (shows "read" state)
    static func markAsOpened() {
        sharedDefaults?.set(true, forKey: "widget_was_opened")
        WidgetCenter.shared.reloadTimelines(ofKind: "SometimesWidget")
    }

    /// Extract first line from poem text
    static func extractFirstLine(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return lines.first ?? String(text.prefix(50))
    }
}

@MainActor
final class PoemStore {
    private var allPoems: [Poem]
    private var deliveredPoemIDs: Set<String>        // Current cycle delivered IDs
    private var allTimeDeliveredIDs: Set<String>     // All poems ever delivered (persisted)
    private let userSalt: Int                         // User-specific randomization salt

    private let container: ModelContainer
    private let context: ModelContext

    // MARK: - Initialization

    init() {
        // Load poems from bundle
        self.allPoems = Self.loadPoemsFromBundle()
        
        // Initialize or load user-specific salt for personalized scoring
        self.userSalt = Self.loadOrCreateUserSalt()

        // Setup SwiftData with fallback to in-memory if persistent storage fails
        let schema = Schema([DeliveredPoemEntity.self])
        let persistentConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            self.container = try ModelContainer(for: schema, configurations: [persistentConfig])
            self.context = ModelContext(container)
        } catch {
            logger.error("Persistent storage failed, falling back to in-memory: \(error.localizedDescription)")

            // Fallback to in-memory storage
            let memoryConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )

            do {
                self.container = try ModelContainer(for: schema, configurations: [memoryConfig])
                self.context = ModelContext(container)
            } catch {
                // This should never happen with in-memory storage
                logger.critical("Failed to create even in-memory SwiftData container: \(error.localizedDescription)")
                fatalError("Cannot initialize poem storage: \(error)")
            }
        }

        // Load delivered poem IDs (both current cycle and all-time)
        let (cycleIDs, allTimeIDs) = Self.loadDeliveredIDs(from: context, totalPoems: allPoems.count)
        self.deliveredPoemIDs = cycleIDs
        self.allTimeDeliveredIDs = allTimeIDs

        // Migrate from UserDefaults if needed
        migrateFromUserDefaultsIfNeeded()
        
        logger.info("PoemStore initialized: \(self.allPoems.count) poems, \(self.deliveredPoemIDs.count) in cycle, \(self.allTimeDeliveredIDs.count) all-time, salt=\(self.userSalt)")
    }

    // MARK: - Static Helpers

    private nonisolated static func loadPoemsFromBundle() -> [Poem] {
        guard let url = Bundle.main.url(forResource: "poems", withExtension: "json") else {
            logger.warning("poems.json not found in bundle, using sample poems")
            return SamplePoems.all
        }

        do {
            let data = try Data(contentsOf: url)
            let poems = try JSONDecoder().decode([Poem].self, from: data)
            return poems
        } catch {
            logger.error("Failed to load poems.json: \(error.localizedDescription)")
            return SamplePoems.all
        }
    }

    private static func loadDeliveredIDs(from context: ModelContext, totalPoems: Int) -> (cycle: Set<String>, allTime: Set<String>) {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            sortBy: [SortDescriptor(\.deliveredAt, order: .reverse)]
        )
        do {
            let entities = try context.fetch(descriptor)
            let allTimeIDs = Set(entities.map { $0.poemID })
            
            // Current cycle: take the most recent N poems where N < total corpus
            // This allows cycling through poems while still tracking all-time history
            let cycleSize = min(entities.count, totalPoems)
            let cycleIDs = Set(entities.prefix(cycleSize).map { $0.poemID })
            
            return (cycleIDs, allTimeIDs)
        } catch {
            logger.error("Failed to load delivered poem IDs: \(error.localizedDescription)")
            return ([], [])
        }
    }
    
    private static func loadOrCreateUserSalt() -> Int {
        let key = "com.sometimes.app.userSalt"
        if UserDefaults.standard.object(forKey: key) != nil {
            return UserDefaults.standard.integer(forKey: key)
        }
        // Create new salt based on install time + random component
        let salt = Int.random(in: 10000...99999)
        UserDefaults.standard.set(salt, forKey: key)
        return salt
    }

    // MARK: - Migration

    private func migrateFromUserDefaultsIfNeeded() {
        let key = "com.sometimes.app.delivered"
        guard let data = UserDefaults.standard.data(forKey: key),
              let oldPoems = try? JSONDecoder().decode([DeliveredPoem].self, from: data),
              !oldPoems.isEmpty else {
            return
        }

        // Check if already have data in SwiftData
        if !deliveredPoemIDs.isEmpty {
            // Already migrated, just clean up
            UserDefaults.standard.removeObject(forKey: key)
            return
        }

        // Migrate each poem
        for delivered in oldPoems {
            let entity = DeliveredPoemEntity(from: delivered)
            context.insert(entity)
            deliveredPoemIDs.insert(delivered.poem.id)
        }

        do {
            try context.save()
            logger.info("Migrated \(oldPoems.count) poems from UserDefaults to SwiftData")
        } catch {
            logger.error("Failed to save migrated poems: \(error.localizedDescription)")
        }
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Poem Selection

    func selectPoem(for context: DeliveryContext) -> Poem? {
        // Step 1: Prioritize poems never received (all-time)
        var candidates = allPoems.filter { !allTimeDeliveredIDs.contains($0.id) }

        // Step 2: If all poems have been received at least once, use cycle-based filtering
        if candidates.isEmpty {
            candidates = allPoems.filter { !deliveredPoemIDs.contains($0.id) }
        }

        // Step 3: If current cycle is complete, reset cycle and use all poems
        if candidates.isEmpty {
            resetDeliveryHistory()
            candidates = allPoems
        }

        guard !candidates.isEmpty else {
            return nil
        }

        // Score all candidates - serendipity-first algorithm
        // Context is a gentle nudge, not a deterministic filter
        let scored = candidates.map { poem in
            (poem: poem, score: scorePoem(poem, for: context))
        }.sorted { $0.score > $1.score }

        // Expanded top-N pool (12 instead of 5) for more variety
        let topCount = min(12, scored.count)
        let topCandidates = Array(scored.prefix(topCount))
        
        // Use weighted random selection favoring higher scores
        return weightedRandomSelection(from: topCandidates)
    }
    
    private func weightedRandomSelection(from candidates: [(poem: Poem, score: Int)]) -> Poem? {
        guard !candidates.isEmpty else { return nil }
        
        // Calculate weights (score + minimum weight to ensure all have a chance)
        let minWeight = 10
        let weights = candidates.map { max($0.score, 0) + minWeight }
        let totalWeight = weights.reduce(0, +)
        
        // Random selection weighted by score
        var random = Int.random(in: 0..<totalWeight)
        for (index, weight) in weights.enumerated() {
            random -= weight
            if random < 0 {
                return candidates[index].poem
            }
        }
        
        return candidates.last?.poem
    }

    /// Serendipity-first scoring algorithm
    /// Context is a gentle nudge, not a deterministic filter.
    /// A winter poem CAN arrive in summer. A night poem CAN arrive at noon. Just less likely.
    ///
    /// SCORING BREAKDOWN:
    /// - Context Match (max 40 pts): timeOfDay +15, season +12, weather +8, specialDate +5
    /// - Random Factor: 0-60 pts (~50% of typical score)
    /// - Never-Received Bonus: +40
    /// - User Salt Variance: 0-20 (ensures unique sequences per user)
    ///
    /// Poems with null/empty context fields remain fully eligible —
    /// they get 0 context points but full random/salt scores.
    private func scorePoem(_ poem: Poem, for context: DeliveryContext) -> Int {
        var score = 0

        // === Context Matching (max 40 points) ===
        // These are gentle nudges, not filters

        // Time of day match (+15)
        if let times = poem.context.timeOfDay, times.contains(context.timeOfDay.rawValue) {
            score += 15
        }

        // Season match (+12)
        if let seasons = poem.context.seasons, seasons.contains(context.season.rawValue) {
            score += 12
        }

        // Weather match (+8)
        if let weather = context.weather,
           let poemWeather = poem.context.weather,
           (poemWeather.contains(weather.rawValue) || poemWeather.contains("any")) {
            score += 8
        }

        // Special date match (+5) — reduced from +50, special dates are nice but not dominant
        if let special = context.specialDate,
           let poemSpecials = poem.context.specialDates,
           poemSpecials.contains(special.rawValue) {
            score += 5
        }

        // === Never Received Bonus (+40) ===
        // Strong bonus for poems never delivered to this user
        if !allTimeDeliveredIDs.contains(poem.id) {
            score += 40
        }

        // === User-Specific Salt (0-20) ===
        // Deterministic but user-unique variance based on poem ID and user salt
        // Ensures different users get different poems even with same context
        let poemHash = poem.id.hashValue
        let saltedScore = abs((poemHash ^ userSalt) % 21)  // 0-20 inclusive
        score += saltedScore

        // === Random Factor (0-60) ===
        // The heart of serendipity — roughly 50% of a typical score
        // This ensures surprise while context provides gentle guidance
        score += Int.random(in: 0...60)

        return score
    }

    private func resetDeliveryHistory() {
        deliveredPoemIDs.removeAll()
        logger.info("Delivery cycle reset - starting new cycle")
    }

    // MARK: - Delivery Tracking

    func markAsDelivered(_ poem: Poem, context deliveryContext: DeliveryContext) {
        // Deduplication: Check if this poem was already delivered today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let poemID = poem.id

        let existingDescriptor = FetchDescriptor<DeliveredPoemEntity>(
            predicate: #Predicate<DeliveredPoemEntity> {
                $0.poemID == poemID && $0.deliveredAt >= today
            }
        )

        do {
            let existingEntries = try context.fetch(existingDescriptor)
            if !existingEntries.isEmpty {
                logger.info("Poem '\(poem.title)' already delivered today - skipping duplicate")
                return
            }
        } catch {
            logger.warning("Failed to check for existing delivery: \(error.localizedDescription)")
            // Continue with insertion on error - better to potentially duplicate than miss delivery
        }

        let delivered = DeliveredPoem(poem: poem, context: deliveryContext)
        let entity = DeliveredPoemEntity(from: delivered)
        self.context.insert(entity)
        deliveredPoemIDs.insert(poem.id)
        allTimeDeliveredIDs.insert(poem.id)  // Track in all-time history
        do {
            try self.context.save()
            logger.info("Delivered poem '\(poem.title)' by \(poem.poet)")

            // Update widget with first line
            let firstLine = WidgetDataManager.extractFirstLine(from: poem.text)
            WidgetDataManager.poemDelivered(firstLine: firstLine, poet: poem.poet)
        } catch {
            logger.error("Failed to save delivered poem '\(poem.title)': \(error.localizedDescription)")
        }
    }

    // MARK: - Poem Lookup

    func findPoem(byID id: String) -> Poem? {
        return allPoems.first { $0.id == id }
    }

    func findDeliveredPoem(byPoemID id: String) -> DeliveredPoem? {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            predicate: #Predicate { $0.poemID == id },
            sortBy: [SortDescriptor(\.deliveredAt, order: .reverse)]
        )

        do {
            guard let entity = try context.fetch(descriptor).first else {
                return nil
            }
            return entity.toDeliveredPoem()
        } catch {
            logger.error("Failed to find delivered poem by ID '\(id)': \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Archive Access

    func getDeliveredPoems() -> [DeliveredPoem] {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            sortBy: [SortDescriptor(\.deliveredAt, order: .reverse)]
        )

        do {
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDeliveredPoem() }
        } catch {
            logger.error("Failed to fetch delivered poems: \(error.localizedDescription)")
            return []
        }
    }

    func getFavorites() -> [DeliveredPoem] {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.deliveredAt, order: .reverse)]
        )

        do {
            let entities = try context.fetch(descriptor)
            return entities.map { $0.toDeliveredPoem() }
        } catch {
            logger.error("Failed to fetch favorites: \(error.localizedDescription)")
            return []
        }
    }

    func toggleFavorite(for deliveryID: UUID) {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            predicate: #Predicate { $0.id == deliveryID }
        )

        do {
            if let entity = try context.fetch(descriptor).first {
                entity.isFavorite.toggle()

                // Capture or clear save context based on new favorite state
                if entity.isFavorite {
                    entity.capturesSaveContext()
                } else {
                    entity.clearSaveContext()
                }

                try context.save()
                // Notify observers that favorites changed
                NotificationCenter.default.post(name: .favoritesChanged, object: nil)
            }
        } catch {
            logger.error("Failed to toggle favorite for delivery ID: \(error.localizedDescription)")
        }
    }

    func toggleFavorite(forPoemID id: String) {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            predicate: #Predicate { $0.poemID == id },
            sortBy: [SortDescriptor(\.deliveredAt, order: .reverse)]
        )

        do {
            if let entity = try context.fetch(descriptor).first {
                entity.isFavorite.toggle()

                // Capture or clear save context based on new favorite state
                if entity.isFavorite {
                    entity.capturesSaveContext()
                } else {
                    entity.clearSaveContext()
                }

                try context.save()
                // Notify observers that favorites changed
                NotificationCenter.default.post(name: .favoritesChanged, object: nil)
            }
        } catch {
            logger.error("Failed to toggle favorite for poem ID '\(id)': \(error.localizedDescription)")
        }
    }

    // MARK: - Stats

    var totalPoemCount: Int { allPoems.count }

    var deliveredCount: Int {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>()
        do {
            return try context.fetchCount(descriptor)
        } catch {
            logger.error("Failed to count delivered poems: \(error.localizedDescription)")
            return 0
        }
    }

    var favoriteCount: Int {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>(
            predicate: #Predicate { $0.isFavorite == true }
        )
        do {
            return try context.fetchCount(descriptor)
        } catch {
            logger.error("Failed to count favorites: \(error.localizedDescription)")
            return 0
        }
    }
}

// MARK: - SwiftData Entity

@Model
final class DeliveredPoemEntity {
    @Attribute(.unique) var id: UUID
    var poemID: String
    var poemTitle: String
    var poemPoet: String
    var poemText: String
    var poemYear: Int?
    var deliveredAt: Date
    var isFavorite: Bool

    // Delivery context (when poem arrived)
    var weatherCondition: String?
    var timeOfDay: String
    var season: String
    var specialDate: String?

    // Save context (when user favorited - captured at moment of save)
    // This data is NOT used in scoring — reserved for future features
    var savedAt: Date?
    var saveWeather: String?
    var saveTimeOfDay: String?
    var saveSeason: String?
    var saveDayOfWeek: String?
    var saveTemperature: Double?
    var saveLocation: String?

    init(from delivered: DeliveredPoem) {
        self.id = delivered.id
        self.poemID = delivered.poem.id
        self.poemTitle = delivered.poem.title
        self.poemPoet = delivered.poem.poet
        self.poemText = delivered.poem.text
        self.poemYear = delivered.poem.year
        self.deliveredAt = delivered.deliveredAt
        self.isFavorite = delivered.isFavorite
        self.weatherCondition = delivered.context.weather?.rawValue
        self.timeOfDay = delivered.context.timeOfDay.rawValue
        self.season = delivered.context.season.rawValue
        self.specialDate = delivered.context.specialDate?.rawValue

        // Save context starts nil - populated when favorited
        self.savedAt = nil
        self.saveWeather = nil
        self.saveTimeOfDay = nil
        self.saveSeason = nil
        self.saveDayOfWeek = nil
        self.saveTemperature = nil
        self.saveLocation = nil
    }

    /// Captures current context when user favorites the poem
    func capturesSaveContext() {
        let context = SaveContext.current()
        self.savedAt = context.savedAt
        self.saveWeather = context.weather
        self.saveTimeOfDay = context.timeOfDay
        self.saveSeason = context.season
        self.saveDayOfWeek = context.dayOfWeek
        self.saveTemperature = context.temperature
        self.saveLocation = context.location
    }

    /// Clears save context when user unfavorites
    func clearSaveContext() {
        self.savedAt = nil
        self.saveWeather = nil
        self.saveTimeOfDay = nil
        self.saveSeason = nil
        self.saveDayOfWeek = nil
        self.saveTemperature = nil
        self.saveLocation = nil
    }

    func toDeliveredPoem() -> DeliveredPoem {
        let poem = Poem(
            id: poemID,
            title: poemTitle,
            poet: poemPoet,
            text: poemText,
            year: poemYear,
            publicDomain: true,
            context: PoemContext(
                timeOfDay: nil,
                seasons: nil,
                weather: nil,
                mood: nil,
                specialDates: nil,
                days: nil
            ),
            meta: PoemMeta(length: "medium", lines: nil, difficulty: nil)
        )

        let weather = weatherCondition.flatMap { WeatherCondition(rawValue: $0) }
        let context = DeliveryContext(weather: weather)

        return DeliveredPoem(
            id: id,
            poem: poem,
            deliveredAt: deliveredAt,
            isFavorite: isFavorite,
            context: context
        )
    }
}

// MARK: - DeliveredPoem Extension

extension DeliveredPoem {
    init(id: UUID, poem: Poem, deliveredAt: Date, isFavorite: Bool, context: DeliveryContext) {
        self.id = id
        self.poem = poem
        self.deliveredAt = deliveredAt
        self.context = context
        self.isFavorite = isFavorite
    }
}
