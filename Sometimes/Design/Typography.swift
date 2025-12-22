// Typography.swift
// Design system for elegant, literary typography

import SwiftUI
import UIKit

// MARK: - Adaptive Colors (Light/Dark Mode)

extension Color {
    /// Warm cream background (light) / Deep charcoal (dark)
    static let poemBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "1C1C1E")  // Deep Charcoal
            : UIColor(hex: "FAFAF8")  // Warm Cream
    })

    /// Off-black text (light) / Cream text (dark)
    static let poemText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "F5F5F0")  // Cream Text
            : UIColor(hex: "1A1A1A")  // Off-Black
    })

    /// Muted sage accent (slightly lighter in dark mode)
    static let poemAccent = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "98A898")  // Lighter Sage
            : UIColor(hex: "7D8C7D")  // Muted Sage
    })

    /// Higher contrast accent for text usage (WCAG 4.5:1 compliant)
    static let poemAccentAccessible = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "A8B8A8")  // Lighter for dark mode
            : UIColor(hex: "5A6B5A")  // Darker for light mode (4.5:1+)
    })

    /// Sophisticated grey (adjusted for dark mode)
    static let poemSecondary = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "9A9A9A")  // Lighter Grey
            : UIColor(hex: "6A6A6A")  // Sophisticated Grey
    })

    /// Subtle divider (adjusted for dark mode)
    static let poemDivider = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "3A3A3C")  // Dark Divider
            : UIColor(hex: "E5E5E0")  // Subtle Divider
    })

    /// Card background (white in light, slightly lighter charcoal in dark)
    static let poemCardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(hex: "2C2C2E")  // Card Dark
            : UIColor(hex: "FFFFFF")  // White
    })

}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Typography Styles

struct PoemTitleStyle: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .font(.custom("Georgia", size: titleFontSize, relativeTo: .title2))
            .fontWeight(.medium)
            .foregroundColor(.poemText)
    }

    private var titleFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 20
        case .medium, .large: return 22
        case .xLarge, .xxLarge: return 24
        case .xxxLarge: return 26
        default: return 28 // Accessibility sizes
        }
    }
}

struct PoemTextStyle: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .font(.custom("Georgia", size: bodyFontSize, relativeTo: .body))
            .foregroundColor(.poemText)
            .lineSpacing(lineSpacing)
    }

    private var bodyFontSize: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 16
        case .medium, .large: return 18
        case .xLarge, .xxLarge: return 20
        case .xxxLarge: return 22
        default: return 24 // Accessibility sizes
        }
    }

    private var lineSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 10
    }
}

struct PoetAttributionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom("Georgia-Italic", size: 16, relativeTo: .subheadline))
            .foregroundColor(.poemSecondary)
    }
}

struct ContextHintStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .medium, design: .default))
            .foregroundColor(.poemAccent)
            .textCase(.lowercase)
            .tracking(0.5)
    }
}

// MARK: - View Extensions

extension View {
    func poemTitle() -> some View {
        modifier(PoemTitleStyle())
    }
    
    func poemText() -> some View {
        modifier(PoemTextStyle())
    }
    
    func poetAttribution() -> some View {
        modifier(PoetAttributionStyle())
    }
    
    func contextHint() -> some View {
        modifier(ContextHintStyle())
    }
}

// MARK: - Poem Card View

struct PoemCard: View {
    let poem: Poem
    let hint: String?
    let showDivider: Bool
    
    init(poem: Poem, hint: String? = nil, showDivider: Bool = true) {
        self.poem = poem
        self.hint = hint
        self.showDivider = showDivider
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let hint = hint {
                Text(hint)
                    .contextHint()
            }
            
            Text(poem.title)
                .poemTitle()
            
            Text(poem.text)
                .poemText()
            
            Text("— \(poem.poet)")
                .poetAttribution()
            
            if showDivider {
                Divider()
                    .background(Color.poemDivider)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - iOS 26 Glass Compatibility

extension View {
    /// Toolbar modifier for glass navigation bars
    @ViewBuilder
    func adaptiveToolbarStyle() -> some View {
        if #available(iOS 26.0, *) {
            self
                .toolbarBackgroundVisibility(.automatic, for: .navigationBar)
                .toolbarBackground(.hidden, for: .tabBar)
        } else {
            self
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    /// Ensures minimum 44x44pt touch target (HIG requirement)
    func ensureMinimumTouchTarget() -> some View {
        self.frame(minWidth: 44, minHeight: 44)
    }
}

// MARK: - Adaptive Card Background

struct AdaptiveCardBackground: View {
    var cornerRadius: CGFloat = 16

    var body: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: min(cornerRadius, 12))
                .fill(Color.poemCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: min(cornerRadius, 12))
                        .stroke(Color.poemDivider, lineWidth: 1)
                )
        }
    }
}

// MARK: - Adaptive Layout for Accessibility

struct AdaptiveHStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: spacing) {
                content
            }
        } else {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - Adaptive Glass Rounded Modifier

extension View {
    /// Applies Liquid Glass with RoundedRectangle shape
    @ViewBuilder
    func adaptiveGlassRounded(cornerRadius: CGFloat = 16, tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        if #available(iOS 26.0, *) {
            if let tint = tint {
                self.background(shape.fill(.clear).glassEffect(.regular.tint(tint), in: shape))
            } else {
                self.background(shape.fill(.clear).glassEffect(.regular, in: shape))
            }
        } else {
            self.background(Color.poemCardBackground, in: shape)
                .overlay(shape.stroke(Color.poemDivider, lineWidth: 1))
        }
    }
}

// MARK: - Adaptive Glass Button Style

struct AdaptiveGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var tintColor: Color = .poemAccent
    var cornerRadius: CGFloat = 100 // Capsule by default

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if cornerRadius >= 100 {
                    capsuleBackground(isPressed: configuration.isPressed)
                } else {
                    roundedBackground(isPressed: configuration.isPressed)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func capsuleBackground(isPressed: Bool) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.tint(tintColor).interactive(), in: .capsule)
            } else {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: .capsule)
            }
        } else {
            Capsule()
                .fill(isProminent ? tintColor : Color.poemCardBackground)
                .opacity(isPressed ? 0.8 : 1.0)
        }
    }

    @ViewBuilder
    private func roundedBackground(isPressed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        if #available(iOS 26.0, *) {
            if isProminent {
                shape
                    .fill(.clear)
                    .glassEffect(.regular.tint(tintColor).interactive(), in: shape)
            } else {
                shape
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            shape
                .fill(isProminent ? tintColor : Color.poemCardBackground)
                .opacity(isPressed ? 0.8 : 1.0)
        }
    }
}

extension ButtonStyle where Self == AdaptiveGlassButtonStyle {
    static var adaptiveGlass: AdaptiveGlassButtonStyle { .init() }

    static func adaptiveGlass(
        prominent: Bool = false,
        tint: Color = .poemAccent,
        cornerRadius: CGFloat = 100
    ) -> AdaptiveGlassButtonStyle {
        .init(isProminent: prominent, tintColor: tint, cornerRadius: cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack {
            PoemCard(
                poem: SamplePoems.all.first!,
                hint: "for a winter evening"
            )
        }
        .padding(.horizontal, 24)
    }
    .background(Color.poemBackground)
}
