// Poem.swift
// Core data model for poems with contextual metadata

import Foundation

// MARK: - Main Model

struct Poem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let poet: String
    let text: String
    let year: Int?
    let publicDomain: Bool

    // Contextual metadata for timing engine
    let context: PoemContext
    let meta: PoemMeta

    // Collections (for future seasonal drops)
    let collections: [String]?

    init(
        id: String = UUID().uuidString,
        title: String,
        poet: String,
        text: String,
        year: Int? = nil,
        publicDomain: Bool = true,
        context: PoemContext,
        meta: PoemMeta,
        collections: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.poet = poet
        self.text = text
        self.year = year
        self.publicDomain = publicDomain
        self.context = context
        self.meta = meta
        self.collections = collections
    }
}

struct PoemContext: Codable, Equatable {
    let timeOfDay: [String]?
    let seasons: [String]?
    let weather: [String]?
    let mood: [String]?
    let specialDates: [String]?
    let days: [String]?
}

struct PoemMeta: Codable, Equatable {
    let length: String // short, medium, long
    let lines: Int?
    let difficulty: String?
}

// MARK: - Delivered Poem

struct DeliveredPoem: Codable, Identifiable, Hashable {
    let id: UUID
    let poem: Poem
    let deliveredAt: Date
    let context: DeliveryContext
    var isFavorite: Bool

    init(poem: Poem, context: DeliveryContext) {
        self.id = UUID()
        self.poem = poem
        self.deliveredAt = Date()
        self.context = context
        self.isFavorite = false
    }

    // Hashable conformance based on unique ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DeliveredPoem, rhs: DeliveredPoem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Enums (Helpers for matching)

enum TimeOfDay: String, CaseIterable, Codable {
    case morning, afternoon, evening, night
    
    static func current() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
}

enum Season: String, CaseIterable, Codable {
    case spring, summer, autumn, winter
    
    static func current() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
}

enum WeatherCondition: String, CaseIterable, Codable {
    case clear, cloudy, rainy, snowy, stormy, foggy, any
}

enum DayType: String, CaseIterable, Codable {
    case weekday, weekend
    
    static func current() -> DayType {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return (weekday == 1 || weekday == 7) ? .weekend : .weekday
    }
}

enum SpecialDate: String, CaseIterable, Codable {
    case newYear = "new_year"
    case winterSolstice = "winter_solstice"
    case summerSolstice = "summer_solstice"
    case springEquinox = "spring_equinox"
    case autumnEquinox = "autumn_equinox"
    case valentines = "valentines"

    static func current() -> SpecialDate? {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)

        switch (month, day) {
        case (1, 1): return .newYear
        case (12, 21): return .winterSolstice
        case (6, 21): return .summerSolstice
        case (3, 20): return .springEquinox
        case (9, 22): return .autumnEquinox
        case (2, 14): return .valentines
        default: return nil
        }
    }
}

// MARK: - Collections (Infrastructure for Future Seasonal Drops)

/// A themed collection of poems that can be unlocked under certain conditions
struct PoemCollection: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let unlockCondition: UnlockCondition

    /// Whether this collection is currently available to the user
    func isUnlocked(poemsReceived: Int, currentDate: Date) -> Bool {
        unlockCondition.isSatisfied(poemsReceived: poemsReceived, currentDate: currentDate)
    }
}

/// Conditions for unlocking a poem collection
enum UnlockCondition: Codable, Equatable {
    case always                         // Available from start
    case afterPoemsReceived(Int)        // Unlock after N poems received
    case seasonalWindow(month: Int, day: Int, duration: Int) // Available during specific dates
    case dateRange(start: Date, end: Date) // Available between dates

    func isSatisfied(poemsReceived: Int, currentDate: Date) -> Bool {
        switch self {
        case .always:
            return true
        case .afterPoemsReceived(let threshold):
            return poemsReceived >= threshold
        case .seasonalWindow(let month, let day, let duration):
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentDay = calendar.component(.day, from: currentDate)
            // Simple check: within the window
            if currentMonth == month {
                return currentDay >= day && currentDay < day + duration
            }
            return false
        case .dateRange(let start, let end):
            return currentDate >= start && currentDate <= end
        }
    }
}
