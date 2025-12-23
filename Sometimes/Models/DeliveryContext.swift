// DeliveryContext.swift
// Captures the ambient context at poem delivery time and save time

import Foundation

// MARK: - Save Context (captured when user favorites a poem)

/// Context captured at the moment a user saves/favorites a poem.
/// This data is NOT used in scoring — reserved for future features
/// (year-end anthology, exportable collections, optional taste analysis).
struct SaveContext: Codable, Equatable {
    let weather: String?        // "rainy", "clear", etc.
    let timeOfDay: String?      // "morning", "evening", etc.
    let season: String?         // "winter", "spring", etc.
    let dayOfWeek: String?      // "Monday", "Tuesday", etc.
    let temperature: Double?    // actual temp if available (future)
    let location: String?       // city name if permission granted (future)
    let savedAt: Date

    /// Creates a SaveContext from current conditions
    static func current(weather: WeatherCondition? = nil) -> SaveContext {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: now)

        return SaveContext(
            weather: weather?.rawValue,
            timeOfDay: TimeOfDay.current().rawValue,
            season: Season.current().rawValue,
            dayOfWeek: dayOfWeek,
            temperature: nil,  // Future: integrate with WeatherService
            location: nil,     // Future: requires location permission
            savedAt: now
        )
    }
}

// MARK: - Delivery Context (captured when poem is delivered)

struct DeliveryContext: Codable {
    let timeOfDay: TimeOfDay
    let season: Season
    let weather: WeatherCondition?
    let dayType: DayType
    let specialDate: SpecialDate?
    let timestamp: Date
    
    init(weather: WeatherCondition? = nil) {
        self.timeOfDay = TimeOfDay.current()
        self.season = Season.current()
        self.weather = weather
        self.dayType = DayType.current()
        self.specialDate = SpecialDate.current()
        self.timestamp = Date()
    }
    
    /// Creates a hint string for the notification
    var hint: String? {
        if let special = specialDate {
            return hintForSpecialDate(special)
        }
        
        // Combine context into a natural phrase
        var components: [String] = []
        
        // Add time-based hint
        switch timeOfDay {
        case .morning: components.append("this morning")
        case .afternoon: break // too generic
        case .evening: components.append("this evening")
        case .night: components.append("the night")
        }
        
        // Add weather hint if notable
        if let weather = weather {
            switch weather {
            case .rainy: components.append("the rain")
            case .snowy: components.append("the snow")
            case .stormy: components.append("the storm")
            case .foggy: components.append("the mist")
            default: break
            }
        }
        
        // Add seasonal hint for special seasons
        switch season {
        case .winter where timeOfDay == .evening:
            return "for a winter evening"
        case .autumn where weather == .rainy:
            return "for an autumn rain"
        default: break
        }
        
        guard !components.isEmpty else { return "for right now" }
        return "for \(components.joined(separator: " and "))"
    }
    
    private func hintForSpecialDate(_ date: SpecialDate) -> String {
        switch date {
        case .newYear: return "for a new beginning"
        case .winterSolstice: return "for the longest night"
        case .summerSolstice: return "for the longest day"
        case .springEquinox: return "for the turning of spring"
        case .autumnEquinox: return "for the changing season"
        case .valentines: return "for love"
        }
    }

    // MARK: - Share Context String

    /// Generates a natural "This Found Me" context string for sharing
    /// Example: "on a rainy Wednesday morning in December"
    var shareContextString: String {
        let formatter = DateFormatter()

        // Get weekday name
        formatter.dateFormat = "EEEE"
        let weekday = formatter.string(from: timestamp)

        // Get month name
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: timestamp)

        // Build the natural phrase
        var components: [String] = []

        // Weather (if notable)
        if let weather = weather {
            switch weather {
            case .rainy: components.append("rainy")
            case .snowy: components.append("snowy")
            case .stormy: components.append("stormy")
            case .foggy: components.append("foggy")
            case .cloudy: components.append("cloudy")
            case .clear: components.append("clear")
            case .any: break
            }
        }

        // Day of week
        components.append(weekday)

        // Time of day
        components.append(timeOfDay.rawValue)

        // Combine: "on a rainy Wednesday morning in December"
        let description = components.joined(separator: " ")
        return "on a \(description) in \(month)"
    }
}
