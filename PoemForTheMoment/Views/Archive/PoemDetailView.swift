// PoemDetailView.swift
// Minimalist, immersive view for a single poem

import SwiftUI

struct PoemDetailView: View {
    let delivered: DeliveredPoem
    @EnvironmentObject var appState: AppState
    @State private var isFavorite: Bool
    @State private var showShareOptions = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    init(delivered: DeliveredPoem) {
        self.delivered = delivered
        _isFavorite = State(initialValue: delivered.isFavorite)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 12) {
                    Text(delivered.poem.title)
                        .font(.custom("Georgia", size: 26))
                        .fontWeight(.medium)
                        .foregroundColor(.poemText)
                        .multilineTextAlignment(.center)

                    Text(delivered.poem.poet)
                        .font(.custom("Georgia-Italic", size: 18))
                        .foregroundColor(.poemSecondary)
                }
                .padding(.top, 40)

                // Poem Text
                Text(delivered.poem.text)
                    .font(.custom("Georgia", size: 19))
                    .foregroundColor(.poemText)
                    .lineSpacing(12)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 24) {
                    Divider()
                        .background(Color.poemDivider)

                    Text(formatFooter(delivered))
                        .font(.custom("Georgia-Italic", size: 15))
                        .foregroundColor(.poemSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 32)
        }
        .background(Color.poemBackground)
        .adaptiveToolbarStyle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button {
                        showShareOptions = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.poemSecondary)
                    }
                    .ensureMinimumTouchTarget()
                    .accessibilityLabel("Share poem")
                    .accessibilityHint("Double tap to open sharing options for this poem")

                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .poemAccent : .poemSecondary)
                            .animation(reduceMotion ? .none : .interactiveSpring, value: isFavorite)
                    }
                    .ensureMinimumTouchTarget()
                    .accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
                    .accessibilityHint("Double tap to \(isFavorite ? "remove this poem from" : "add this poem to") your favorites")
                    .accessibilityAddTraits(isFavorite ? .isSelected : [])
                }
            }
        }
        .sheet(isPresented: $showShareOptions) {
            ShareOptionsView(delivered: delivered)
        }
        .task {
            // Sync with current state from store on appear
            if let current = appState.poemStore.findDeliveredPoem(byPoemID: delivered.poem.id) {
                isFavorite = current.isFavorite
            }
        }
    }

    private func toggleFavorite() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Optimistic update for immediate UI feedback
        isFavorite.toggle()
        appState.poemStore.toggleFavorite(for: delivered.id)
    }

    private func formatFooter(_ delivered: DeliveredPoem) -> String {
        let date = delivered.deliveredAt
        let dateStr = date.formatted(Date.FormatStyle().weekday(.wide).month(.wide).day())
        let timeStr = date.formatted(Date.FormatStyle().hour().minute())

        var context = "Arrived \(dateStr)\n\(timeStr)"

        if let weather = delivered.context.weather {
            context += " · \(weather.rawValue)"
        }

        return context
    }
}

// MARK: - Share Options View

struct ShareOptionsView: View {
    let delivered: DeliveredPoem
    @Environment(\.dismiss) var dismiss
    @State private var selectedAspect: ShareAspectRatio = .standard
    @State private var useDarkMode = false
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                if isGenerating {
                    ProgressView()
                        .frame(height: 300)
                } else if let image = generatedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }

                // Options
                VStack(spacing: 16) {
                    Picker("Format", selection: $selectedAspect) {
                        Text("Standard").tag(ShareAspectRatio.standard)
                        Text("Square").tag(ShareAspectRatio.square)
                        Text("Story").tag(ShareAspectRatio.story)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Dark Background", isOn: $useDarkMode)
                        .font(.subheadline)
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    showShareSheet = true
                } label: {
                    Text("Share Image")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.adaptiveGlass(prominent: true, tint: .poemAccent))
                .padding(.horizontal)
                .accessibilityHint("Double tap to share this poem as an image")
            }
            .padding(.vertical)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedAspect) { _, _ in
                Task { await regenerateImage() }
            }
            .onChange(of: useDarkMode) { _, _ in
                Task { await regenerateImage() }
            }
            .task { await regenerateImage() }
            .sheet(isPresented: $showShareSheet) {
                if let image = generatedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    @MainActor
    private func regenerateImage() async {
        isGenerating = true
        // Yield to allow UI to update before heavy rendering
        await Task.yield()
        generatedImage = ShareImageGenerator.generateImage(
            for: delivered,
            aspectRatio: selectedAspect,
            darkMode: useDarkMode
        )
        isGenerating = false
    }
}

// MARK: - Share Image Generator

enum ShareAspectRatio {
    case story      // 9:16 for Instagram Stories
    case square     // 1:1 for Instagram posts
    case standard   // 4:5 for general use

    var size: CGSize {
        switch self {
        case .story:    return CGSize(width: 1080, height: 1920)
        case .square:   return CGSize(width: 1080, height: 1080)
        case .standard: return CGSize(width: 1080, height: 1350)
        }
    }
}

struct ShareImageGenerator {
    @MainActor
    static func generateImage(for delivered: DeliveredPoem, aspectRatio: ShareAspectRatio = .standard, darkMode: Bool = false) -> UIImage {
        let size = aspectRatio.size
        let view = ShareImageView(delivered: delivered, size: size, darkMode: darkMode)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0

        return renderer.uiImage ?? UIImage()
    }
}

private struct ShareImageView: View {
    let delivered: DeliveredPoem
    let size: CGSize
    let darkMode: Bool

    private var backgroundColor: Color {
        darkMode ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.98, green: 0.98, blue: 0.97)
    }

    private var textColor: Color {
        darkMode ? Color(red: 0.96, green: 0.96, blue: 0.94) : Color(red: 0.1, green: 0.1, blue: 0.1)
    }

    private var secondaryColor: Color {
        darkMode ? Color(red: 0.56, green: 0.56, blue: 0.58) : Color(red: 0.42, green: 0.42, blue: 0.42)
    }

    private var accentColor: Color {
        darkMode ? Color(red: 0.60, green: 0.66, blue: 0.60) : Color(red: 0.49, green: 0.55, blue: 0.49)
    }

    private var dividerColor: Color {
        darkMode ? Color(red: 0.23, green: 0.23, blue: 0.24) : Color(red: 0.9, green: 0.9, blue: 0.88)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                Text(delivered.poem.title)
                    .font(.custom("Georgia", size: 36))
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Text(delivered.poem.poet)
                    .font(.custom("Georgia-Italic", size: 24))
                    .foregroundColor(secondaryColor)

                Text(delivered.poem.text)
                    .font(.custom("Georgia", size: 22))
                    .foregroundColor(textColor)
                    .lineSpacing(12)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: size.width * 0.8)
            }

            Spacer()

            VStack(spacing: 16) {
                Rectangle()
                    .fill(dividerColor)
                    .frame(width: 60, height: 1)

                Text(contextString)
                    .font(.custom("Georgia-Italic", size: 16))
                    .foregroundColor(secondaryColor)

                Text("Poem for the Moment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
                    .tracking(1.5)
                    .textCase(.uppercase)
            }
            .padding(.bottom, 48)
        }
        .frame(width: size.width, height: size.height)
        .background(backgroundColor)
    }

    private var contextString: String {
        let weekday = delivered.deliveredAt.formatted(Date.FormatStyle().weekday(.wide))
        var context = "Arrived on a \(weekday.lowercased())"

        if let weather = delivered.context.weather {
            context += " \(weather.rawValue)"
        }

        context += " \(delivered.context.timeOfDay.rawValue)"

        return context
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
