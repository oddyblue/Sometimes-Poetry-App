// NotificationManager.swift
// Handles notification permissions and scheduling

import Foundation
import UserNotifications
import OSLog

private let logger = Logger(subsystem: "com.sometimes.app", category: "Notifications")

final class NotificationManager: ObservableObject, @unchecked Sendable {
    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // Category identifiers
    static let poemCategory = "POEM_DELIVERY"

    // Action identifiers
    static let saveAction = "SAVE_POEM"
    static let readLaterAction = "READ_LATER"
    static let dismissAction = "DISMISS"

    init() {
        checkAuthorization()
        registerCategories()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run {
                isAuthorized = granted
            }
            logger.info("Notification authorization \(granted ? "granted" : "denied")")
            return granted
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Categories & Actions

    private func registerCategories() {
        // Save to Favorites - primary action
        let saveAction = UNNotificationAction(
            identifier: Self.saveAction,
            title: "Save to Favorites",
            options: [.foreground],
            icon: UNNotificationActionIcon(systemImageName: "heart.fill")
        )

        // Read Later - queues for later reading
        let readLaterAction = UNNotificationAction(
            identifier: Self.readLaterAction,
            title: "Read Later",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "clock")
        )

        let category = UNNotificationCategory(
            identifier: Self.poemCategory,
            actions: [saveAction, readLaterAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )

        center.setNotificationCategories([category])
    }

    // MARK: - Scheduling

    func schedulePoem(_ poem: Poem, at date: Date, hint: String?) async {
        let content = createNotificationContent(for: poem, hint: hint)

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "poem-\(poem.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            logger.info("Scheduled poem '\(poem.title)' for \(date)")
        } catch {
            logger.error("Failed to schedule poem notification: \(error.localizedDescription)")
        }
    }

    func deliverPoemNow(_ poem: Poem, hint: String?) async {
        let content = createNotificationContent(for: poem, hint: hint)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "poem-test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            logger.info("Delivering test poem '\(poem.title)' immediately")
        } catch {
            logger.error("Failed to deliver test poem: \(error.localizedDescription)")
        }
    }

    private func createNotificationContent(for poem: Poem, hint: String?) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        // Title and attribution
        content.title = poem.title
        content.subtitle = "by \(poem.poet)"

        // Show teaser (first 2-3 lines) in banner, full text in expanded view
        let lines = poem.text.components(separatedBy: "\n").filter { !$0.isEmpty }
        let teaser = lines.prefix(3).joined(separator: "\n")
        content.body = teaser + (lines.count > 3 ? "\n..." : "")

        // Metadata
        content.categoryIdentifier = Self.poemCategory
        content.threadIdentifier = "poems"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        // Full poem data for detail view
        content.userInfo = [
            "poemID": poem.id,
            "title": poem.title,
            "poet": poem.poet,
            "text": poem.text,
            "hint": hint ?? ""
        ]

        return content
    }

    func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let savePoemToFavorites = Notification.Name("savePoemToFavorites")
    static let poemDelivered = Notification.Name("poemDelivered")
    static let navigateToPoem = Notification.Name("navigateToPoem")
    static let favoritesChanged = Notification.Name("favoritesChanged")
}
