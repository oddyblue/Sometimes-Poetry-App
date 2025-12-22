// OnboardingFlow.swift
// 6-step editorial onboarding flow

import SwiftUI
import UserNotifications

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var activeHoursStart = 7
    @State private var activeHoursEnd = 22
    @State private var poemsPerWeek = 3
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePage(onContinue: { withAnimation { currentPage = 1 } })
                .tag(0)
            
            ConceptPage(onContinue: { withAnimation { currentPage = 2 } })
                .tag(1)
            
            ActiveHoursPage(
                startHour: $activeHoursStart,
                endHour: $activeHoursEnd,
                onContinue: { withAnimation { currentPage = 3 } }
            )
            .tag(2)
            
            FrequencyPage(
                frequency: $poemsPerWeek,
                onContinue: { withAnimation { currentPage = 4 } }
            )
            .tag(3)
            
            NotificationPage(onContinue: { withAnimation { currentPage = 5 } })
                .tag(4)
                
            DonePage(onComplete: completeOnboarding)
                .tag(5)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.poemBackground)
        .ignoresSafeArea()
    }
    
    private func completeOnboarding() {
        appState.settings.activeHoursStart = activeHoursStart
        appState.settings.activeHoursEnd = activeHoursEnd
        appState.settings.poemsPerWeek = poemsPerWeek
        appState.settings.save()
        appState.completeOnboarding()
    }
}

// MARK: - 1. Welcome Page

struct WelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Text("Sometimes")
                    .font(.custom("Georgia", size: 36))
                    .foregroundColor(.poemText)
                    .accessibilityAddTraits(.isHeader)

                Text("A poem arrives.")
                    .font(.custom("Georgia-Italic", size: 20))
                    .foregroundColor(.poemSecondary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            OnboardingButton(title: "Continue", action: onContinue)
                .accessibilityHint("Double tap to continue to the next step")
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 2. The Concept

struct ConceptPage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Poetry finds you.")
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.poemText)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("A few times each week, a poem\narrives — chosen for this moment.\n\nThe weather. The time of day.\nThe season.\n\nRead it in the notification.\nSave it for later.\n\nThat's it.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(.poemSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }

            Spacer()

            OnboardingButton(title: "Continue", action: onContinue)
                .accessibilityHint("Double tap to continue to the next step")
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 3. Active Hours Page

struct ActiveHoursPage: View {
    @Binding var startHour: Int
    @Binding var endHour: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("When can poems arrive?")
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.poemText)
                    .accessibilityAddTraits(.isHeader)

                Text("Poems will only arrive during\nthese hours.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.poemSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            Spacer()

            HStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("From")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.poemSecondary)

                    Menu {
                        ForEach(5..<22, id: \.self) { hour in
                            Button(formatHour(hour)) {
                                startHour = hour
                                if endHour <= startHour {
                                    endHour = startHour + 1
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(formatHour(startHour))
                                .font(.custom("Georgia", size: 22))
                                .foregroundColor(.poemText)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.poemSecondary)
                        }
                        .frame(width: 140, height: 60)
                        .adaptiveGlassRounded(cornerRadius: 12)
                    }
                    .accessibilityLabel("Start time, \(formatHour(startHour))")
                    .accessibilityHint("Double tap to change when poems can start arriving")
                }

                VStack(spacing: 12) {
                    Text("Until")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.poemSecondary)

                    Menu {
                        ForEach((startHour + 1)..<25, id: \.self) { hour in
                            Button(formatHour(hour)) {
                                endHour = hour
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(formatHour(endHour))
                                .font(.custom("Georgia", size: 22))
                                .foregroundColor(.poemText)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.poemSecondary)
                        }
                        .frame(width: 140, height: 60)
                        .adaptiveGlassRounded(cornerRadius: 12)
                    }
                    .accessibilityLabel("End time, \(formatHour(endHour))")
                    .accessibilityHint("Double tap to change when poems stop arriving")
                }
            }
            .padding(.bottom, 40)

            OnboardingButton(title: "Continue", action: onContinue)
                .accessibilityHint("Double tap to continue to the next step")
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h == 12 { return "12 PM" }
        if h < 12 { return "\(h) AM" }
        return "\(h - 12) PM"
    }
}

// MARK: - 4. Frequency Page

struct FrequencyPage: View {
    @Binding var frequency: Int
    let onContinue: () -> Void

    private let options: [(value: Int, label: String, description: String)] = [
        (3, "3 per week", "A gentle rhythm"),
        (4, "4 per week", "Balanced"),
        (5, "5 per week", "More frequent"),
        (7, "Daily", "A poem every day")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text("How often?")
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.poemText)
                    .accessibilityAddTraits(.isHeader)

                Text("You can change this anytime\nin settings.")
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(.poemSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                ForEach(options, id: \.value) { option in
                    Button(action: { frequency = option.value }) {
                        HStack(spacing: 16) {
                            Image(systemName: frequency == option.value ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(frequency == option.value ? .poemAccent : .poemSecondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.label)
                                    .font(.custom("Georgia", size: 18))
                                    .foregroundColor(.poemText)

                                Text(option.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.poemSecondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .adaptiveGlassRounded(cornerRadius: 12)
                    }
                    .accessibilityLabel("\(option.label), \(option.description)")
                    .accessibilityHint(frequency == option.value ? "Currently selected" : "Double tap to select")
                    .accessibilityAddTraits(frequency == option.value ? .isSelected : [])
                    .ensureMinimumTouchTarget()
                }

                OnboardingButton(title: "Continue", action: onContinue)
                    .accessibilityHint("Double tap to continue to the next step")
                    .padding(.top, 24)
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - 5. Notification Page

struct NotificationPage: View {
    let onContinue: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("One thing.")
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.poemText)
                    .accessibilityAddTraits(.isHeader)

                Text("Poems arrive as notifications.\nThe notification is the experience.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(.poemSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }

            Spacer()

            OnboardingButton(
                title: isRequesting ? "..." : "Enable Notifications",
                action: requestNotifications
            )
            .disabled(isRequesting)
            .accessibilityLabel(isRequesting ? "Requesting notification permission" : "Enable Notifications")
            .accessibilityHint(isRequesting ? "Please wait" : "Double tap to allow poem notifications")
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }

    private func requestNotifications() {
        isRequesting = true
        Task {
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                onContinue()
            }
        }
    }
}

// MARK: - 6. Done Page

struct DonePage: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("You're ready.")
                    .font(.custom("Georgia", size: 24))
                    .foregroundColor(.poemText)
                    .accessibilityAddTraits(.isHeader)

                Text("Your first poem will arrive\nwithin the next day or two.\n\nUntil then, there's nothing\nto do here.")
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(.poemSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
            }

            Spacer()

            OnboardingButton(title: "Close", action: onComplete)
                .accessibilityHint("Double tap to finish setup and start using the app")
                .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
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
        .ensureMinimumTouchTarget()
    }
}
