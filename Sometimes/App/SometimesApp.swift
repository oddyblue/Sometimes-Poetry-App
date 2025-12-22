// SometimesApp.swift
// The main entry point for Poem for the Moment

import SwiftUI
import UserNotifications

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate immediately on launch
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        if let poemID = userInfo["poemID"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .poemDelivered,
                    object: nil,
                    userInfo: ["poemID": poemID]
                )
            }
        }

        completionHandler([.banner, .list, .sound])
    }

    // Handle notification taps and actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        guard let poemID = userInfo["poemID"] as? String else {
            completionHandler()
            return
        }

        DispatchQueue.main.async {
            // Mark poem as delivered
            NotificationCenter.default.post(
                name: .poemDelivered,
                object: nil,
                userInfo: ["poemID": poemID]
            )

            // Handle specific actions
            switch response.actionIdentifier {
            case NotificationManager.saveAction:
                // Save to favorites and navigate to poem
                NotificationCenter.default.post(
                    name: .savePoemToFavorites,
                    object: nil,
                    userInfo: ["poemID": poemID]
                )
                NotificationCenter.default.post(
                    name: .navigateToPoem,
                    object: nil,
                    userInfo: ["poemID": poemID]
                )

            case NotificationManager.readLaterAction:
                // Poem is already in archive - just dismiss notification
                break

            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification - navigate to poem
                NotificationCenter.default.post(
                    name: .navigateToPoem,
                    object: nil,
                    userInfo: ["poemID": poemID]
                )

            default:
                break
            }
        }

        completionHandler()
    }
}

@main
struct SometimesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onReceive(NotificationCenter.default.publisher(for: .savePoemToFavorites)) { notification in
                    if let poemID = notification.userInfo?["poemID"] as? String {
                        appState.poemStore.toggleFavorite(forPoemID: poemID)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .poemDelivered)) { notification in
                    if let poemID = notification.userInfo?["poemID"] as? String {
                        Task {
                            await appState.timingEngine.onPoemDelivered(poemID: poemID)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPoem)) { notification in
                    if let poemID = notification.userInfo?["poemID"] as? String {
                        // Switch to Poems tab first, then navigate to poem
                        appState.selectedTab = 0
                        appState.pendingDeepLinkPoemID = poemID
                    }
                }
                .task {
                    // Check and reschedule on app launch if needed
                    if appState.hasCompletedOnboarding {
                        await appState.timingEngine.checkAndRescheduleIfNeeded()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && appState.hasCompletedOnboarding {
                        // Check scheduling when app becomes active
                        Task {
                            await appState.timingEngine.checkAndRescheduleIfNeeded()
                        }
                    }
                }
        }
    }
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var settings: UserSettings
    @Published var pendingDeepLinkPoemID: String?
    @Published var selectedTab: Int = 0

    let poemStore: PoemStore
    let notificationManager: NotificationManager
    let timingEngine: TimingEngine
    
    init() {
        let store = PoemStore()
        let loadedSettings = UserSettings.load()
        let notifManager = NotificationManager()
        
        // Initialize all stored properties first
        self.poemStore = store
        self.notificationManager = notifManager
        self.settings = loadedSettings
        self.hasCompletedOnboarding = loadedSettings.hasCompletedOnboarding
        
        // Now initialize timing engine
        self.timingEngine = TimingEngine(
            poemStore: store,
            notificationManager: notifManager,
            settings: loadedSettings
        )
    }
    
    func completeOnboarding() {
        settings.hasCompletedOnboarding = true
        settings.save()
        hasCompletedOnboarding = true
        
        // Update timing engine with new settings
        Task {
            await timingEngine.updateSettings(settings)
            await timingEngine.scheduleNextPoem()
        }
    }
    
    func updateSettings(_ newSettings: UserSettings) {
        let oldSettings = settings
        settings = newSettings
        settings.save()

        // Sync with timing engine and reschedule if timing-related settings changed
        Task {
            await timingEngine.updateSettings(newSettings)

            // Reschedule if active hours or frequency changed (and not paused)
            let timingChanged = oldSettings.activeHoursStart != newSettings.activeHoursStart ||
                               oldSettings.activeHoursEnd != newSettings.activeHoursEnd ||
                               oldSettings.poemsPerWeek != newSettings.poemsPerWeek

            if timingChanged && !newSettings.isPaused {
                notificationManager.cancelAllPendingNotifications()
                await timingEngine.scheduleNextPoem()
            }
        }
    }
}
