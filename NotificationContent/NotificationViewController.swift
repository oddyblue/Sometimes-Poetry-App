// NotificationViewController.swift
// The container controller for the rich notification interface

import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var hostingController: UIHostingController<PoemNotificationView>?

    // Default background colors matching the app theme
    private var lightBackground: UIColor {
        UIColor(red: 0.98, green: 0.98, blue: 0.97, alpha: 1.0)  // Warm Cream
    }

    private var darkBackground: UIColor {
        UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)  // Deep Charcoal
    }

    private var currentBackground: UIColor {
        traitCollection.userInterfaceStyle == .dark ? darkBackground : lightBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set solid background matching the app theme
        view.backgroundColor = currentBackground
        // Set initial content size
        preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 300)

        // Register for trait changes (iOS 17+)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (vc: NotificationViewController, _) in
            self?.handleAppearanceChange()
        }
    }

    private func handleAppearanceChange() {
        view.backgroundColor = currentBackground

        if let hosting = hostingController {
            let isDarkMode = traitCollection.userInterfaceStyle == .dark
            hosting.view.backgroundColor = currentBackground
            hosting.rootView = PoemNotificationView(
                poem: hosting.rootView.poem,
                isDarkMode: isDarkMode
            )
        }
    }

    func didReceive(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo

        // Extract data
        guard let title = userInfo["title"] as? String,
              let poet = userInfo["poet"] as? String,
              let text = userInfo["text"] as? String else {
            return
        }

        let hint = userInfo["hint"] as? String

        // Create Poem display model
        let poem = PoemDisplayModel(title: title, poet: poet, text: text, hint: hint)

        // Detect dark mode
        let isDarkMode = traitCollection.userInterfaceStyle == .dark

        // Create SwiftUI view
        let rootView = PoemNotificationView(poem: poem, isDarkMode: isDarkMode)
        let hosting = UIHostingController(rootView: rootView)
        // Use solid background that matches the SwiftUI view's background
        hosting.view.backgroundColor = currentBackground

        // Remove previous hosting controller if any
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        // Add as child
        addChild(hosting)
        view.addSubview(hosting.view)

        // Layout with Auto Layout
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hosting.didMove(toParent: self)
        hostingController = hosting

        // Force layout pass
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Calculate intrinsic size
        let targetWidth = UIScreen.main.bounds.width
        let fittingSize = hosting.sizeThatFits(in: CGSize(width: targetWidth, height: .greatestFiniteMagnitude))

        // Set preferred content size
        preferredContentSize = CGSize(width: targetWidth, height: max(fittingSize.height, 300))
    }

}
