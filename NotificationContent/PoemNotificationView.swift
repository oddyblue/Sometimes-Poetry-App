// PoemNotificationView.swift
// SwiftUI view for the rich notification

import SwiftUI

// Local model for display within extension
struct PoemDisplayModel {
    let title: String
    let poet: String
    let text: String
    let hint: String?
}

struct PoemNotificationView: View {
    let poem: PoemDisplayModel
    let isDarkMode: Bool

    // Explicit colors based on mode
    private var backgroundColor: Color {
        isDarkMode
            ? Color(red: 0.11, green: 0.11, blue: 0.12)  // Deep Charcoal
            : Color(red: 0.98, green: 0.98, blue: 0.97)  // Warm Cream
    }

    private var textColor: Color {
        isDarkMode
            ? Color(red: 0.96, green: 0.96, blue: 0.94)  // Light text
            : Color(red: 0.1, green: 0.1, blue: 0.1)     // Dark text
    }

    private var secondaryColor: Color {
        isDarkMode
            ? Color(red: 0.56, green: 0.56, blue: 0.58)  // Gray
            : Color(red: 0.42, green: 0.42, blue: 0.42)  // Dark gray
    }

    private var accentColor: Color {
        isDarkMode
            ? Color(red: 0.60, green: 0.66, blue: 0.60)  // Sage green light
            : Color(red: 0.49, green: 0.55, blue: 0.49)  // Sage green dark
    }

    private var dividerColor: Color {
        isDarkMode
            ? Color(red: 0.3, green: 0.3, blue: 0.32)    // Dark divider
            : Color(red: 0.85, green: 0.85, blue: 0.83)  // Light divider
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .center, spacing: 20) {
                // Header: Title & Poet
                VStack(spacing: 8) {
                    Text(poem.title)
                        .font(.custom("Georgia", size: 22))
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("by \(poem.poet)")
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundColor(secondaryColor)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(poem.title) by \(poem.poet)")

                // Decorative divider
                Rectangle()
                    .fill(dividerColor)
                    .frame(width: 40, height: 1)
                    .accessibilityHidden(true)

                // Poem Text
                Text(poem.text)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(textColor)
                    .lineSpacing(8)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Context hint
                if let hint = poem.hint, !hint.isEmpty {
                    VStack(spacing: 12) {
                        Rectangle()
                            .fill(dividerColor)
                            .frame(width: 40, height: 1)
                            .accessibilityHidden(true)

                        Text(hint)
                            .font(.custom("Georgia-Italic", size: 13))
                            .foregroundColor(secondaryColor)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("Selected for: \(hint)")
                    }
                    .padding(.top, 8)
                }

                // App branding
                Text("Poem for the Moment")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accentColor)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity)
        .background {
            notificationBackground
        }
    }

    @ViewBuilder
    private var notificationBackground: some View {
        if #available(iOS 26.0, *) {
            // iOS 26: Use glass effect for notification
            RoundedRectangle(cornerRadius: 20)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        } else {
            // Legacy: Solid background
            backgroundColor
        }
    }
}
