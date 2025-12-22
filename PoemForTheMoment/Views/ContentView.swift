// ContentView.swift
// Root view that handles onboarding vs main app

import SwiftUI

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

    var body: some View {
        if #available(iOS 26.0, *) {
            // iOS 26+: New Tab struct with Liquid Glass floating tab bar
            TabView(selection: $appState.selectedTab) {
                Tab("Poems", systemImage: "book.closed", value: 0) {
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
                        Label("Poems", systemImage: "book.closed")
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
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
