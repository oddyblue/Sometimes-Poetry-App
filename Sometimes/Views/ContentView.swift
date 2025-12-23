// ContentView.swift
// Root view that handles onboarding vs main app

import SwiftUI
import UserNotifications

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlow()
            }
        }
    }
}

// MARK: - Main Tab View (iOS 26 Liquid Glass + Legacy)

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) var scenePhase
    @State private var showNotificationAlert = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                // iOS 26+: New Tab struct with Liquid Glass floating tab bar
                TabView(selection: $appState.selectedTab) {
                    Tab("Archive", systemImage: "book.closed", value: 0) {
                        ArchiveView()
                    }
                    Tab("Settings", systemImage: "gearshape", value: 1) {
                        SettingsView()
                    }
                }
                .tint(.poemAccent)
                .tabBarMinimizeBehavior(.onScrollDown)
            } else {
                // iOS 18-25: Standard tabItem approach
                TabView(selection: $appState.selectedTab) {
                    ArchiveView()
                        .tabItem {
                            Label("Archive", systemImage: "book.closed")
                        }
                        .tag(0)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .tag(1)
                }
                .tint(.poemAccent)
            }
        }
        .sheet(isPresented: $showNotificationAlert) {
            NotificationRequiredSheet(onOpenSettings: openSettings, onDismiss: {
                showNotificationAlert = false
            })
            .interactiveDismissDisabled()
        }
        .task {
            await checkNotificationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await checkNotificationStatus()
                }
            }
        }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationStatus = settings.authorizationStatus
            // Show alert if notifications are denied
            if settings.authorizationStatus == .denied {
                showNotificationAlert = true
            } else {
                showNotificationAlert = false
            }
        }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Notification Required Sheet

struct NotificationRequiredSheet: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon
                Image(systemName: "bell.slash")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.poemAccent)

                VStack(spacing: 16) {
                    Text("Notifications are off")
                        .font(.custom("Georgia", size: 26))
                        .foregroundColor(.poemText)

                    Text("Sometimes delivers poems through notifications.\nWithout them, you won't receive any poems.")
                        .font(.custom("Georgia", size: 17))
                        .foregroundColor(.poemSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                // Primary action
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.poemAccent)
                        .cornerRadius(12)
                }

                // Secondary action (less prominent)
                Button(action: onDismiss) {
                    Text("Remind me later")
                        .font(.system(size: 15))
                        .foregroundColor(.poemSecondary)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.poemBackground)
        .presentationBackground(Color.poemBackground)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
