// OnboardingFlow.swift
// Curated editorial onboarding experience

import SwiftUI
import UserNotifications

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var activeHoursStart = 8
    @State private var activeHoursEnd = 20
    @State private var poemsPerWeek = 7  // Daily by default

    private let totalPages = 6

    var body: some View {
        ZStack {
            Color.poemBackground
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                WelcomePage(onContinue: advance)
                    .tag(0)

                MagicPage(onContinue: advance)
                    .tag(1)

                TimingPage(
                    startHour: $activeHoursStart,
                    endHour: $activeHoursEnd,
                    onContinue: advance
                )
                .tag(2)

                RhythmPage(
                    frequency: $poemsPerWeek,
                    onContinue: advance
                )
                .tag(3)

                NotificationPermissionPage(onContinue: advance)
                    .tag(4)

                ReadyPage(onComplete: completeOnboarding)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Progress indicator
            VStack {
                Spacer()
                ProgressDots(current: currentPage, total: totalPages)
                    .padding(.bottom, 20)
            }
            .ignoresSafeArea(.keyboard)
        }
    }

    private func advance() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        appState.settings.activeHoursStart = activeHoursStart
        appState.settings.activeHoursEnd = activeHoursEnd
        appState.settings.poemsPerWeek = poemsPerWeek
        appState.settings.save()
        appState.completeOnboarding()
    }
}

// MARK: - Progress Dots

struct ProgressDots: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.poemText.opacity(0.8) : Color.poemText.opacity(0.2))
                    .frame(width: 6, height: 6)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}

// MARK: - 1. Welcome

struct WelcomePage: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            VStack(spacing: 16) {
                Text("Sometimes")
                    .font(.custom("Georgia", size: 48))
                    .fontWeight(.regular)
                    .foregroundColor(.poemText)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                Text("a poem arrives")
                    .font(.custom("Georgia-Italic", size: 20))
                    .foregroundColor(.poemSecondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: appeared)
            }
            .accessibilityElement(children: .combine)

            Spacer()
            Spacer()
            Spacer()

            Button(action: onContinue) {
                Text("Begin")
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(.poemText)
                    .frame(width: 120, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: appeared)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }
}

// MARK: - 2. The Magic (How It Works)

struct MagicPage: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            VStack(spacing: 40) {
                Text("Chosen for\nthis moment")
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(.poemText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                VStack(spacing: 20) {
                    Text("Each poem arrives when\nthe moment feels right.")
                        .font(.custom("Georgia", size: 17))
                        .foregroundColor(.poemSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)

                    Text("The hour. The weather.\nThe season of the year.")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(.poemSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: appeared)
                }
            }

            Spacer()
            Spacer()
            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(.poemText)
                    .frame(width: 140, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - 3. Timing Window

struct TimingPage: View {
    @Binding var startHour: Int
    @Binding var endHour: Int
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("Your hours")
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(.poemText)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                Text("When should poetry find you?")
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundColor(.poemSecondary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)
            }

            Spacer()

            // Time selection
            HStack(spacing: 24) {
                TimeSelector(
                    label: "From",
                    hour: $startHour,
                    hours: Array(0..<24),
                    onSelect: { hour in
                        if endHour <= hour {
                            endHour = min(hour + 4, 24)
                        }
                    }
                )

                Text("—")
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(.poemSecondary.opacity(0.5))
                    .padding(.top, 28)

                TimeSelector(
                    label: "Until",
                    hour: $endHour,
                    hours: Array(max(1, startHour + 1)...24),
                    onSelect: { _ in }
                )
            }
            .padding(.horizontal, 20)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

            Spacer()
            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(.poemText)
                    .frame(width: 140, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

struct TimeSelector: View {
    let label: String
    @Binding var hour: Int
    let hours: [Int]
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.poemSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Menu {
                ForEach(hours, id: \.self) { h in
                    Button(formatHour(h)) {
                        hour = h
                        onSelect(h)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(formatHour(hour))
                        .font(.custom("Georgia", size: 20))
                        .foregroundColor(.poemText)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.poemSecondary)
                }
                .frame(width: 110, height: 52)
                .background(Color.poemCardBackground)
                .cornerRadius(10)
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h == 12 { return "12 PM" }
        if h < 12 { return "\(h) AM" }
        return "\(h - 12) PM"
    }
}

// MARK: - 4. Rhythm (Frequency)

struct RhythmPage: View {
    @Binding var frequency: Int
    let onContinue: () -> Void
    @State private var appeared = false

    private let options: [(value: Int, title: String, subtitle: String)] = [
        (3, "A few times", "Gentle, unhurried"),
        (5, "Most days", "A steady presence"),
        (7, "Every day", "A daily ritual")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Text("Your rhythm")
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(.poemText)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                Text("How often should poetry find you?")
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundColor(.poemSecondary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)
            }

            Spacer()

            VStack(spacing: 10) {
                ForEach(options, id: \.value) { option in
                    FrequencyOption(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: frequency == option.value,
                        action: { frequency = option.value }
                    )
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)

            Text("You can always change this later.")
                .font(.custom("Georgia-Italic", size: 13))
                .foregroundColor(.poemSecondary.opacity(0.6))
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: appeared)

            Spacer()
            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(.poemText)
                    .frame(width: 140, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

struct FrequencyOption: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(isSelected ? Color.poemAccent : Color.poemSecondary.opacity(0.4), lineWidth: 1.5)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.poemAccent : Color.clear)
                            .padding(4)
                    )
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.custom("Georgia", size: 17))
                        .foregroundColor(.poemText)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.poemSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.poemCardBackground)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 5. Notification Permission

struct NotificationPermissionPage: View {
    let onContinue: () -> Void
    @Environment(\.scenePhase) var scenePhase
    @State private var permissionState: PermissionState = .unknown
    @State private var isRequesting = false
    @State private var appeared = false

    enum PermissionState {
        case unknown
        case notDetermined
        case denied
        case authorized
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Text("One thing")
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(.poemText)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                VStack(spacing: 16) {
                    Text("Poems arrive as notifications.")
                        .font(.custom("Georgia", size: 17))
                        .foregroundColor(.poemSecondary)
                        .multilineTextAlignment(.center)

                    Text("This is the experience itself.")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(.poemSecondary.opacity(0.7))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: appeared)
            }

            Spacer()

            // Dynamic content based on permission state
            VStack(spacing: 16) {
                switch permissionState {
                case .unknown, .notDetermined:
                    Button(action: requestPermission) {
                        Text(isRequesting ? "..." : "Allow Notifications")
                            .font(.custom("Georgia", size: 17))
                            .foregroundColor(.poemText)
                            .frame(width: 200, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(isRequesting)

                case .denied:
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text("Notifications are off")
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(.poemText)

                            Text("Without them, poems\ncan't reach you.")
                                .font(.custom("Georgia", size: 15))
                                .foregroundColor(.poemSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: openSettings) {
                            Text("Open Settings")
                                .font(.custom("Georgia", size: 17))
                                .foregroundColor(.poemText)
                                .frame(width: 160, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                                )
                        }

                        Button("Continue anyway") {
                            onContinue()
                        }
                        .font(.custom("Georgia-Italic", size: 14))
                        .foregroundColor(.poemSecondary.opacity(0.6))
                    }

                case .authorized:
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.poemAccent)
                            Text("Enabled")
                                .font(.custom("Georgia", size: 15))
                                .foregroundColor(.poemSecondary)
                        }

                        Button(action: onContinue) {
                            Text("Continue")
                                .font(.custom("Georgia", size: 17))
                                .foregroundColor(.poemText)
                                .frame(width: 140, height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
        .onAppear {
            checkPermissionState()
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Re-check when returning from Settings
            if newPhase == .active {
                checkPermissionState()
            }
        }
    }

    private func checkPermissionState() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    permissionState = .notDetermined
                case .denied:
                    permissionState = .denied
                case .authorized, .provisional, .ephemeral:
                    permissionState = .authorized
                @unknown default:
                    permissionState = .notDetermined
                }
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    isRequesting = false
                    if granted {
                        permissionState = .authorized
                        // Brief delay to show success state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onContinue()
                        }
                    } else {
                        permissionState = .denied
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    permissionState = .denied
                }
            }
        }
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - 6. Ready

struct ReadyPage: View {
    let onComplete: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()

            VStack(spacing: 32) {
                Text("Now we wait")
                    .font(.custom("Georgia", size: 32))
                    .foregroundColor(.poemText)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                VStack(spacing: 12) {
                    Text("Your first poem will arrive soon.")
                        .font(.custom("Georgia", size: 17))
                        .foregroundColor(.poemSecondary)

                    Text("Until then, there is nothing to do.")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(.poemSecondary.opacity(0.7))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: appeared)
            }

            Spacer()
            Spacer()
            Spacer()

            Button(action: onComplete) {
                Text("Begin")
                    .font(.custom("Georgia", size: 17))
                    .foregroundColor(.poemText)
                    .frame(width: 120, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.poemText.opacity(0.3), lineWidth: 1)
                    )
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: appeared)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

// MARK: - Components

struct OnboardingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.poemText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.adaptiveGlass(cornerRadius: 12))
        .frame(minHeight: 50)
    }
}
