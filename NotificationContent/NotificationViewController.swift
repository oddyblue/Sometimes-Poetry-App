// NotificationViewController.swift
// Rich notification content extension for displaying full poems

import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var hostingController: UIHostingController<AnyView>?

    // Theme colors matching the app
    private var lightBackground: UIColor {
        UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1.0)
    }

    private var darkBackground: UIColor {
        UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
    }

    private var currentBackground: UIColor {
        traitCollection.userInterfaceStyle == .dark ? darkBackground : lightBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = currentBackground

        // Initial size - will be adjusted when content loads
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 300)

        // Register for trait changes (iOS 17+)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: NotificationViewController, _) in
            self?.handleAppearanceChange()
        }
    }

    private func handleAppearanceChange() {
        view.backgroundColor = currentBackground
        // Recreate the view with new appearance if we have a hosting controller
        if hostingController != nil {
            // The appearance change will be picked up by SwiftUI automatically
            hostingController?.view.backgroundColor = currentBackground
        }
    }

    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        // Extract poem data from notification payload
        let title = userInfo["title"] as? String
        let poet = userInfo["poet"] as? String
        let text = userInfo["text"] as? String
        let hint = userInfo["hint"] as? String

        // Create the appropriate view
        let rootView: AnyView

        if let title = title, let poet = poet, let text = text, !text.isEmpty {
            // Full poem view
            let poem = PoemDisplayModel(title: title, poet: poet, text: text, hint: hint)
            rootView = AnyView(PoemNotificationView(poem: poem, isDarkMode: isDarkMode))
        } else {
            // Fallback view - show notification content if poem data is missing
            let fallbackTitle = notification.request.content.title
            let fallbackBody = notification.request.content.body
            rootView = AnyView(FallbackNotificationView(
                title: fallbackTitle,
                message: fallbackBody,
                isDarkMode: isDarkMode
            ))
        }

        // Remove previous hosting controller if any
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        // Create and configure hosting controller
        let hosting = UIHostingController(rootView: rootView)
        hosting.view.backgroundColor = currentBackground
        
        // Disable safe area insets to prevent layout issues
        hosting.view.insetsLayoutMarginsFromSafeArea = false

        // Add new hosting controller
        addChild(hosting)
        view.addSubview(hosting.view)

        // Layout constraints
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hosting.didMove(toParent: self)
        hostingController = hosting

        // Force layout and calculate proper size
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let targetWidth = UIScreen.main.bounds.width
        let fittingSize = hosting.sizeThatFits(in: CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude))

        // Set preferred content size with minimum height
        let height = max(fittingSize.height, 200)
        preferredContentSize = CGSize(width: targetWidth, height: height)
    }
}

// MARK: - Fallback View

struct FallbackNotificationView: View {
    let title: String
    let message: String
    let isDarkMode: Bool

    private var textColor: Color {
        isDarkMode ? Color(red: 0.96, green: 0.96, blue: 0.94) : Color(red: 0.1, green: 0.1, blue: 0.1)
    }

    private var secondaryColor: Color {
        isDarkMode ? Color(red: 0.56, green: 0.56, blue: 0.58) : Color(red: 0.42, green: 0.42, blue: 0.42)
    }

    private var backgroundColor: Color {
        isDarkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 0.97)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.custom("Georgia", size: 20))
                .fontWeight(.medium)
                .foregroundColor(textColor)

            Text(message)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(secondaryColor)
                .lineSpacing(8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
    }
}
