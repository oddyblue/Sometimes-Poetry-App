// SettingsView.swift
// Refined settings with improved frequency options and UX

import SwiftUI
import UserNotifications
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) var scenePhase
    @State private var testPoemStatus: String?
    @State private var isTestingPoem = false
    @State private var showPauseOptions = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @StateObject private var donationManager = DonationManager()
    @State private var showDonationSuccess = false

    // Use computed binding to sync with appState
    private var settings: Binding<UserSettings> {
        Binding(
            get: { appState.settings },
            set: { appState.updateSettings($0) }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Delivery Section
                Section {
                    NavigationLink {
                        FrequencySettingView(
                            frequency: settings.poemsPerWeek,
                            onSave: { appState.updateSettings(appState.settings) }
                        )
                    } label: {
                        Label {
                            HStack {
                                Text("Frequency")
                                Spacer()
                                Text(appState.settings.frequencyDescription)
                                    .foregroundColor(.poemSecondary)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.poemAccent)
                        }
                    }
                    .accessibilityLabel("Frequency, currently \(appState.settings.frequencyDescription)")
                    .accessibilityHint("Double tap to change how often you receive poems")

                    NavigationLink {
                        ActiveHoursSettingView(
                            startHour: settings.activeHoursStart,
                            endHour: settings.activeHoursEnd,
                            onSave: { appState.updateSettings(appState.settings) }
                        )
                    } label: {
                        Label {
                            HStack {
                                Text("Active Hours")
                                Spacer()
                                Text("\(formatHour(appState.settings.activeHoursStart)) – \(formatHour(appState.settings.activeHoursEnd))")
                                    .foregroundColor(.poemSecondary)
                            }
                        } icon: {
                            Image(systemName: "clock")
                                .foregroundColor(.poemAccent)
                        }
                    }
                    .accessibilityLabel("Active Hours, currently \(formatHour(appState.settings.activeHoursStart)) to \(formatHour(appState.settings.activeHoursEnd))")
                    .accessibilityHint("Double tap to change when poems can arrive")
                } header: {
                    Text("Delivery")
                } footer: {
                    Text("Poems arrive at random times within your active hours.")
                }

                // MARK: - Pause Section
                Section {
                    if appState.settings.isPaused {
                        // Currently paused state
                        HStack {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Delivery Paused")
                                        .foregroundColor(.primary)
                                    if let days = appState.settings.remainingPauseDays {
                                        Text("\(days) day\(days == 1 ? "" : "s") remaining")
                                            .font(.caption)
                                            .foregroundColor(.poemSecondary)
                                    }
                                }
                            } icon: {
                                Image(systemName: "pause.circle.fill")
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)

                        Button {
                            var updated = appState.settings
                            updated.resume()
                            appState.updateSettings(updated)
                            Task {
                                await appState.timingEngine.scheduleNextPoem()
                            }
                        } label: {
                            Label("Resume Delivery", systemImage: "play.circle")
                        }
                        .foregroundColor(.poemAccent)
                        .accessibilityHint("Double tap to start receiving poems again")
                    } else {
                        // Not paused - show pause options
                        Button {
                            showPauseOptions = true
                        } label: {
                            Label {
                                HStack {
                                    Text("Pause Delivery")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.poemSecondary)
                                }
                            } icon: {
                                Image(systemName: "pause.circle")
                                    .foregroundColor(.poemAccent)
                            }
                        }
                        .foregroundColor(.primary)
                        .accessibilityHint("Double tap to temporarily pause poem delivery")
                    }
                } footer: {
                    if !appState.settings.isPaused {
                        Text("Take a break without losing your preferences.")
                    }
                }

                // MARK: - Notifications Section
                Section {
                    HStack {
                        Label {
                            Text("Notifications")
                        } icon: {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.poemAccent)
                        }
                        Spacer()
                        switch notificationStatus {
                        case .authorized, .provisional, .ephemeral:
                            Text("Enabled")
                                .foregroundColor(.poemAccentAccessible)
                        case .denied:
                            Button("Open Settings") {
                                openNotificationSettings()
                            }
                            .foregroundColor(.poemAccent)
                        case .notDetermined:
                            Button("Enable") {
                                Task {
                                    await appState.notificationManager.requestAuthorization()
                                    checkNotificationStatus()
                                }
                            }
                            .foregroundColor(.poemAccent)
                        @unknown default:
                            Text("Unknown")
                                .foregroundColor(.poemSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Notifications \(notificationStatus == .authorized ? "enabled" : "disabled")")
                } footer: {
                    switch notificationStatus {
                    case .denied:
                        Text("Notifications are off. Open Settings to enable poem delivery.")
                            .foregroundColor(.orange)
                    case .notDetermined:
                        Text("Enable notifications to receive poems.")
                    case .authorized, .provisional, .ephemeral:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }

                // MARK: - Test Section
                Section {
                    Button {
                        sendTestPoem(delay: 0)
                    } label: {
                        Label {
                            HStack {
                                Text(isTestingPoem ? "Sending..." : "Send Now")
                                Spacer()
                                if isTestingPoem {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        } icon: {
                            Image(systemName: "paperplane")
                                .foregroundColor(.poemAccent)
                        }
                    }
                    .disabled(isTestingPoem)
                    .foregroundColor(.primary)

                    Button {
                        sendTestPoem(delay: 10)
                    } label: {
                        Label("Send in 10 seconds", systemImage: "clock")
                            .foregroundColor(.primary)
                    }
                    .disabled(isTestingPoem)

                    if let status = testPoemStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Check") ? .orange : .poemAccentAccessible)
                            .accessibilityLabel("Status: \(status)")
                    }
                } header: {
                    Text("Test Notifications")
                } footer: {
                    Text("Send a test poem to verify notifications work.")
                }

                // MARK: - Support Section
                Section {
                    if donationManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if donationManager.products.isEmpty {
                        Button {
                            Task {
                                await donationManager.loadProducts()
                            }
                        } label: {
                            Label("Retry Loading", systemImage: "arrow.clockwise")
                                .foregroundColor(.poemAccent)
                        }
                    } else {
                        ForEach(donationManager.products, id: \.id) { product in
                            DonationProductRow(
                                product: product,
                                donationManager: donationManager,
                                showSuccess: $showDonationSuccess
                            )
                        }
                    }

                    if let error = donationManager.purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Support Sometimes")
                } footer: {
                    Text("Sometimes is free with no ads. If you enjoy receiving poetry, consider leaving a tip to support continued development.")
                }

                // MARK: - About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.poemSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Version 1.0.0")
                } header: {
                    Text("About")
                } footer: {
                    Text("Sometimes delivers poetry at meaningful moments.")
                        .font(.footnote)
                        .foregroundColor(.poemSecondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .adaptiveToolbarStyle()
            .sheet(isPresented: $showPauseOptions) {
                PauseDurationSheet { days in
                    var updated = appState.settings
                    updated.pauseFor(days: days)
                    appState.updateSettings(updated)
                    appState.notificationManager.cancelAllPendingNotifications()
                    showPauseOptions = false
                }
            }
            .alert("Thank You!", isPresented: $showDonationSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your support means everything. Thank you for helping keep Sometimes alive.")
            }
            .onAppear {
                checkNotificationStatus()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Re-check when returning from Settings
                if newPhase == .active {
                    checkNotificationStatus()
                }
            }
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func openNotificationSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h == 12 { return "12 PM" }
        if h < 12 { return "\(h) AM" }
        return "\(h - 12) PM"
    }

    private func sendTestPoem(delay: Int) {
        isTestingPoem = true
        testPoemStatus = nil

        Task {
            if !appState.notificationManager.isAuthorized {
                let granted = await appState.notificationManager.requestAuthorization()
                if !granted {
                    await MainActor.run {
                        testPoemStatus = "Check notification permissions in Settings"
                        isTestingPoem = false
                    }
                    return
                }
            }

            if delay > 0 {
                await MainActor.run {
                    testPoemStatus = "Sending in \(delay) seconds..."
                }
                try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
            }

            await appState.timingEngine.deliverPoemNow()

            await MainActor.run {
                testPoemStatus = "Poem sent! Check your notifications."
                isTestingPoem = false
            }

            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await MainActor.run {
                testPoemStatus = nil
            }
        }
    }
}

// MARK: - Pause Duration Sheet

struct PauseDurationSheet: View {
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) var dismiss

    private let options: [(days: Int, label: String, description: String)] = [
        (3, "3 days", "Short break"),
        (7, "1 week", "Recommended"),
        (14, "2 weeks", "Extended break"),
        (30, "1 month", "Long pause")
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(options, id: \.days) { option in
                        Button {
                            onSelect(option.days)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.label)
                                        .foregroundColor(.primary)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundColor(.poemSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.poemSecondary)
                            }
                        }
                        .accessibilityLabel("Pause for \(option.label)")
                        .accessibilityHint(option.description)
                    }
                } footer: {
                    Text("You can resume anytime from Settings.")
                }
            }
            .navigationTitle("Pause Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Active Hours Setting

struct ActiveHoursSettingView: View {
    @Binding var startHour: Int
    @Binding var endHour: Int
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                Picker("From", selection: $startHour) {
                    ForEach(5..<22, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .accessibilityLabel("Start time")
                .accessibilityHint("Select when poems can start arriving")

                Picker("To", selection: $endHour) {
                    ForEach((startHour + 1)..<25, id: \.self) { hour in
                        Text(formatHour(hour)).tag(hour)
                    }
                }
                .accessibilityLabel("End time")
                .accessibilityHint("Select when poems should stop arriving")
            } footer: {
                Text("Poems will only arrive during these hours. We recommend a window of at least 8 hours for the best experience.")
            }
        }
        .navigationTitle("Active Hours")
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveToolbarStyle()
        .onChange(of: startHour) { _, _ in onSave() }
        .onChange(of: endHour) { _, _ in onSave() }
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h == 12 { return "12 PM" }
        if h < 12 { return "\(h) AM" }
        return "\(h - 12) PM"
    }
}

// MARK: - Frequency Setting

struct FrequencySettingView: View {
    @Binding var frequency: Int
    let onSave: () -> Void
    @State private var showCustomPicker = false

    // Preset options
    private let presets: [(value: Int, label: String, description: String)] = [
        (3, "3 per week", "Gentle rhythm"),
        (4, "4 per week", "Balanced"),
        (5, "5 per week", "More frequent"),
        (7, "Daily", "A poem every day")
    ]

    // Is the current frequency a preset?
    private var isPreset: Bool {
        presets.contains { $0.value == frequency }
    }

    var body: some View {
        Form {
            // Presets Section
            Section {
                ForEach(presets, id: \.value) { preset in
                    Button {
                        frequency = preset.value
                        onSave()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.label)
                                    .foregroundColor(.primary)
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundColor(.poemSecondary)
                            }
                            Spacer()
                            if frequency == preset.value {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.poemAccent)
                            }
                        }
                    }
                    .accessibilityLabel(preset.label)
                    .accessibilityHint(frequency == preset.value ? "Currently selected" : "Double tap to select. \(preset.description)")
                    .accessibilityAddTraits(frequency == preset.value ? .isSelected : [])
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Choose how often poems arrive.")
            }

            // Custom Section
            Section {
                Button {
                    showCustomPicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Custom")
                                .foregroundColor(.primary)
                            Text("Set your own frequency")
                                .font(.caption)
                                .foregroundColor(.poemSecondary)
                        }
                        Spacer()
                        if !isPreset {
                            Text("\(frequency) per week")
                                .foregroundColor(.poemAccent)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.poemSecondary)
                    }
                }
                .accessibilityLabel("Custom frequency\(!isPreset ? ", currently \(frequency) per week" : "")")
                .accessibilityHint("Double tap to set a custom number of poems per week")
            }
        }
        .navigationTitle("Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .adaptiveToolbarStyle()
        .sheet(isPresented: $showCustomPicker) {
            CustomFrequencySheet(frequency: $frequency) {
                onSave()
                showCustomPicker = false
            }
        }
    }
}

// MARK: - Custom Frequency Sheet

struct CustomFrequencySheet: View {
    @Binding var frequency: Int
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var tempFrequency: Int = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 16) {
                    Text("\(tempFrequency)")
                        .font(.system(size: 72, weight: .light, design: .rounded))
                        .foregroundColor(.poemText)

                    Text(tempFrequency == 1 ? "poem per week" : "poems per week")
                        .font(.custom("Georgia-Italic", size: 18))
                        .foregroundColor(.poemSecondary)
                }

                // Stepper-style buttons
                HStack(spacing: 40) {
                    Button {
                        if tempFrequency > 1 {
                            tempFrequency -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(tempFrequency > 1 ? .poemAccent : .poemSecondary.opacity(0.3))
                    }
                    .disabled(tempFrequency <= 1)
                    .accessibilityLabel("Decrease")
                    .accessibilityHint("Currently \(tempFrequency)")

                    Button {
                        if tempFrequency < 7 {
                            tempFrequency += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(tempFrequency < 7 ? .poemAccent : .poemSecondary.opacity(0.3))
                    }
                    .disabled(tempFrequency >= 7)
                    .accessibilityLabel("Increase")
                    .accessibilityHint("Currently \(tempFrequency)")
                }

                Spacer()

                Button {
                    frequency = tempFrequency
                    onSave()
                } label: {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.adaptiveGlass(prominent: true, tint: .poemAccent, cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.poemBackground)
            .navigationTitle("Custom Frequency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            tempFrequency = frequency
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Donation Product Row

struct DonationProductRow: View {
    let product: Product
    @ObservedObject var donationManager: DonationManager
    @Binding var showSuccess: Bool
    @State private var isPurchasing = false

    var body: some View {
        Button {
            purchase()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: product.donationIcon)
                    .font(.title2)
                    .foregroundColor(.poemAccent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.donationDisplayName)
                        .foregroundColor(.primary)
                        .font(.body)
                    Text(product.donationDescription)
                        .font(.caption)
                        .foregroundColor(.poemSecondary)
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(product.displayPrice)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.poemAccent)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(isPurchasing)
        .accessibilityLabel("\(product.donationDisplayName), \(product.displayPrice)")
        .accessibilityHint(product.donationDescription)
    }

    private func purchase() {
        isPurchasing = true

        Task {
            let success = await donationManager.purchase(product)

            await MainActor.run {
                isPurchasing = false
                if success {
                    showSuccess = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
