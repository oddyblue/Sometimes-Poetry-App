// UserSettings.swift
// User preferences persisted to UserDefaults

import Foundation

struct UserSettings: Codable {
    // Delivery preferences
    var activeHoursStart: Int = 7   // 7 AM
    var activeHoursEnd: Int = 22    // 10 PM
    var poemsPerWeek: Int = 3       // 1-7 (daily)
    
    // App state
    var hasCompletedOnboarding: Bool = false
    var pauseUntilDate: Date? = nil
    
    // Computed
    var isPaused: Bool {
        guard let pauseUntil = pauseUntilDate else { return false }
        return Date() < pauseUntil
    }
    
    // MARK: - Persistence
    
    private static let key = "com.poemforthemoment.settings"
    
    static func load() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data)
        else {
            return UserSettings()
        }
        return settings
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
    
    // MARK: - Mutations
    
    mutating func setActiveHours(start: Int, end: Int) {
        activeHoursStart = max(0, min(23, start))
        activeHoursEnd = max(1, min(24, end))
        save()
    }
    
    mutating func setFrequency(_ frequency: Int) {
        poemsPerWeek = max(1, min(7, frequency))
        save()
    }

    // MARK: - Frequency Helpers

    /// Returns a human-readable description of the frequency
    var frequencyDescription: String {
        switch poemsPerWeek {
        case 1: return "Once a week"
        case 7: return "Daily"
        default: return "\(poemsPerWeek) per week"
        }
    }

    /// Returns true if using daily delivery
    var isDaily: Bool {
        poemsPerWeek == 7
    }
    
    mutating func pauseFor(days: Int) {
        pauseUntilDate = Calendar.current.date(byAdding: .day, value: days, to: Date())
        save()
    }

    mutating func pauseForOneWeek() {
        pauseFor(days: 7)
    }

    mutating func resume() {
        pauseUntilDate = nil
        save()
    }

    /// Returns remaining pause days, or nil if not paused
    var remainingPauseDays: Int? {
        guard let pauseUntil = pauseUntilDate, isPaused else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: pauseUntil).day ?? 0
        return max(0, days)
    }
}
