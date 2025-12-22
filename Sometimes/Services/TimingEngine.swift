// TimingEngine.swift
// Core algorithm for scheduling poem delivery at meaningful moments

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.sometimes.app", category: "Timing")

actor TimingEngine {
    private let poemStore: PoemStore
    private let notificationManager: NotificationManager
    private var settings: UserSettings
    private let weatherService: WeatherService

    private var nextScheduledDate: Date?
    private var scheduledPoemID: String?

    // UserDefaults key for persisting scheduled poem info
    private let scheduledPoemKey = "com.sometimes.app.scheduledPoem"

    init(poemStore: PoemStore, notificationManager: NotificationManager, settings: UserSettings) {
        self.poemStore = poemStore
        self.notificationManager = notificationManager
        self.settings = settings
        self.weatherService = WeatherService()

        // Load any previously scheduled poem info
        let (date, poemID) = Self.loadScheduledPoemInfo()
        self.nextScheduledDate = date
        self.scheduledPoemID = poemID
    }

    // MARK: - Persistence (Static Helper)

    private static func loadScheduledPoemInfo() -> (Date?, String?) {
        let key = "com.sometimes.app.scheduledPoem"
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return (nil, nil)
        }
        do {
            let info = try JSONDecoder().decode(ScheduledPoemInfo.self, from: data)
            return (info.scheduledDate, info.poemID)
        } catch {
            logger.error("Failed to decode scheduled poem info: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    private func saveScheduledPoemInfo() {
        if let date = nextScheduledDate, let poemID = scheduledPoemID {
            let info = ScheduledPoemInfo(poemID: poemID, scheduledDate: date)
            do {
                let data = try JSONEncoder().encode(info)
                UserDefaults.standard.set(data, forKey: scheduledPoemKey)
            } catch {
                logger.error("Failed to encode scheduled poem info: \(error.localizedDescription)")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: scheduledPoemKey)
        }
    }

    private func clearScheduledPoemInfo() {
        nextScheduledDate = nil
        scheduledPoemID = nil
        UserDefaults.standard.removeObject(forKey: scheduledPoemKey)
    }

    // MARK: - Public API

    func scheduleNextPoem() async {
        // Reload settings in case they changed
        settings = UserSettings.load()

        guard !settings.isPaused else {
            return
        }

        // Cancel any existing notifications first
        notificationManager.cancelAllPendingNotifications()

        // Calculate next delivery time
        let deliveryDate = calculateNextDeliveryTime()

        // Get weather forecast for that time
        let weather = await weatherService.getWeather()

        // Create context
        let context = DeliveryContext(weather: weather)

        // Select appropriate poem
        guard let poem = await poemStore.selectPoem(for: context) else {
            return
        }

        // Schedule notification
        await notificationManager.schedulePoem(
            poem,
            at: deliveryDate,
            hint: context.hint
        )

        // Store scheduled info (not marked as delivered yet)
        nextScheduledDate = deliveryDate
        scheduledPoemID = poem.id
        saveScheduledPoemInfo()

        logger.info("Scheduled '\(poem.title)' for \(deliveryDate)")
    }

    /// Called when a notification is delivered to mark poem and schedule next
    func onPoemDelivered(poemID: String) async {
        logger.info("Poem delivered: \(poemID)")

        // Mark the poem as delivered now
        let weather = await weatherService.getWeather()
        let context = DeliveryContext(weather: weather)

        if let poem = await poemStore.findPoem(byID: poemID) {
            await poemStore.markAsDelivered(poem, context: context)
        }

        // Clear current scheduled info
        clearScheduledPoemInfo()

        // Schedule the next poem
        await scheduleNextPoem()
    }

    /// Check and reschedule if needed (called on app launch)
    func checkAndRescheduleIfNeeded() async {
        let pending = await notificationManager.getPendingNotifications()

        if pending.isEmpty {
            // No pending notifications, schedule one
            await scheduleNextPoem()
        } else if let scheduledDate = nextScheduledDate, scheduledDate < Date() {
            // Scheduled date has passed but notification didn't fire
            // This can happen if the app was force-quit
            await scheduleNextPoem()
        }
    }

    func updateSettings(_ newSettings: UserSettings) {
        settings = newSettings
    }

    // MARK: - Timing Algorithm

    private func calculateNextDeliveryTime() -> Date {
        let calendar = Calendar.current
        let now = Date()

        // Calculate average interval based on frequency
        let daysPerPoem = 7.0 / Double(settings.poemsPerWeek)
        let baseIntervalHours = daysPerPoem * 24

        // Add variance: ±25% of the interval
        let variance = baseIntervalHours * 0.25
        let randomVariance = Double.random(in: -variance...variance)
        let intervalHours = baseIntervalHours + randomVariance

        // Calculate base delivery date
        var deliveryDate = now.addingTimeInterval(intervalHours * 3600)

        // Adjust to fall within active hours
        deliveryDate = adjustToActiveHours(deliveryDate)

        // Add minute-level randomness (±15-45 minutes as per spec)
        let randomMinutes = Int.random(in: 15...45) * (Bool.random() ? 1 : -1)
        deliveryDate = calendar.date(byAdding: .minute, value: randomMinutes, to: deliveryDate) ?? deliveryDate

        // Ensure it's in the future (at least 1 hour)
        let minimumDate = now.addingTimeInterval(3600)
        if deliveryDate <= minimumDate {
            deliveryDate = minimumDate
            deliveryDate = adjustToActiveHours(deliveryDate)
        }

        return deliveryDate
    }

    private func adjustToActiveHours(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let hour = components.hour ?? 12

        // Calculate valid hour range
        let rangeSize = max(1, settings.activeHoursEnd - settings.activeHoursStart)

        if hour < settings.activeHoursStart {
            // Too early, move to a random time within active hours
            components.hour = settings.activeHoursStart + Int.random(in: 0..<rangeSize)
            components.minute = Int.random(in: 0...59)
        } else if hour >= settings.activeHoursEnd {
            // Too late, move to next day's active hours
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: date) else {
                return date
            }
            components = calendar.dateComponents([.year, .month, .day], from: nextDay)
            components.hour = settings.activeHoursStart + Int.random(in: 0..<rangeSize)
            components.minute = Int.random(in: 0...59)
        }

        return calendar.date(from: components) ?? date
    }

    // MARK: - Debug

    func getNextScheduledDate() -> Date? {
        return nextScheduledDate
    }

    /// For testing: deliver a poem immediately
    func deliverPoemNow() async {
        let weather = await weatherService.getWeather()
        let context = DeliveryContext(weather: weather)

        guard let poem = await poemStore.selectPoem(for: context) else {
            logger.warning("No poem available for test delivery")
            return
        }

        await notificationManager.deliverPoemNow(poem, hint: context.hint)
        await poemStore.markAsDelivered(poem, context: context)

        // Schedule next poem after a delay to avoid canceling the test notification
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await self.scheduleNextPoem()
        }
    }
}

// MARK: - Helper Types

private struct ScheduledPoemInfo: Codable {
    let poemID: String
    let scheduledDate: Date
}
