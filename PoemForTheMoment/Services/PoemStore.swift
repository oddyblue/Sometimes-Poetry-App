// PoemStore.swift
// Manages poem corpus, delivery history, and favorites
// Uses SwiftData for persistent storage of delivered poems

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.poemforthemoment", category: "PoemStore")

@MainActor
final class PoemStore {
    private var allPoems: [Poem]
    private var deliveredPoemIDs: Set<String>

    private let container: ModelContainer
    private let context: ModelContext

    // MARK: - Initialization

    init() {
        // Load poems from bundle
        self.allPoems = Self.loadPoemsFromBundle()

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

        // Load delivered poem IDs
        self.deliveredPoemIDs = Self.loadDeliveredIDs(from: context)

        // Migrate from UserDefaults if needed
        migrateFromUserDefaultsIfNeeded()
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

    private static func loadDeliveredIDs(from context: ModelContext) -> Set<String> {
        let descriptor = FetchDescriptor<DeliveredPoemEntity>()
        do {
            let entities = try context.fetch(descriptor)
            return Set(entities.map { $0.poemID })
        } catch {
            logger.error("Failed to load delivered poem IDs: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Migration

    private func migrateFromUserDefaultsIfNeeded() {
        let key = "com.poemforthemoment.delivered"
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
        var candidates = allPoems.filter { !deliveredPoemIDs.contains($0.id) }

        if candidates.isEmpty {
            resetDeliveryHistory()
            candidates = allPoems
        }

        guard !candidates.isEmpty else {
            return nil
        }

        let scored = candidates.map { poem in
            (poem: poem, score: scorePoem(poem, for: context))
        }.sorted { $0.score > $1.score }

        let topCount = min(5, scored.count)
        let topCandidates = Array(scored.prefix(topCount))

        return topCandidates.randomElement()?.poem
    }

    private func scorePoem(_ poem: Poem, for context: DeliveryContext) -> Int {
        var score = 0

        if let times = poem.context.timeOfDay, times.contains(context.timeOfDay.rawValue) {
            score += 30
        }

        if let seasons = poem.context.seasons, seasons.contains(context.season.rawValue) {
            score += 25
        }

        if let weather = context.weather,
           let poemWeather = poem.context.weather,
           (poemWeather.contains(weather.rawValue) || poemWeather.contains("any")) {
            score += 20
        }

        if let special = context.specialDate,
           let poemSpecials = poem.context.specialDates,
           poemSpecials.contains(special.rawValue) {
            score += 50
        }

        score += Int.random(in: 0...10)

        return score
    }

    private func resetDeliveryHistory() {
        deliveredPoemIDs.removeAll()
    }

    // MARK: - Delivery Tracking

    func markAsDelivered(_ poem: Poem, context deliveryContext: DeliveryContext) {
        let delivered = DeliveredPoem(poem: poem, context: deliveryContext)
        let entity = DeliveredPoemEntity(from: delivered)
        self.context.insert(entity)
        deliveredPoemIDs.insert(poem.id)
        do {
            try self.context.save()
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
                try context.save()
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
                try context.save()
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
    var weatherCondition: String?
    var timeOfDay: String
    var season: String
    var specialDate: String?

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
