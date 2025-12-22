// DeliveryContext.swift
// Captures the ambient context at poem delivery time

import Foundation

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
}
