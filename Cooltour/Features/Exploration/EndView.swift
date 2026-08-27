import SwiftData
import SwiftUI
import UIKit

// MARK: - End View (post-tour completion)

/// Shown after End Tour when the walk recorded at least one site.
/// Save & Continue is the only exit — title/theme edit inline below the collage.
struct EndView: View {
  @Environment(AppEnvironment.self) private var env
  let walk: Walk
  let onSaveAndContinue: () -> Void

  @State private var walkTitle: String
  @State private var selectedTheme: CulturalColorTheme = .blue
  @State private var isEditingTitle: Bool = false
  @FocusState private var isTitleFieldFocused: Bool
  /// Replay on this screen is view-scoped. If we started playback, leaving must stop it
  /// so the story does not keep playing in the global player / miniplayer.
  @State private var ownsPlayback: Bool = false

  private let maxTitleCharacters: Int = 50

  init(walk: Walk, onSaveAndContinue: @escaping () -> Void) {
    self.walk = walk
    self.onSaveAndContinue = onSaveAndContinue

    let events = walk.triggerEvents.sorted { $0.firedAt < $1.firedAt }
    let defaultTitle: String
    if events.isEmpty {
      defaultTitle = "Walk on \(walk.startedAt.formatted(date: .abbreviated, time: .omitted))"
    } else {
      let names = events.map(\.siteName)
      let unique = Array(NSOrderedSet(array: names)).compactMap { $0 as? String }
      if let first = unique.first, let last = unique.last, first != last {
        defaultTitle = "\(first) - \(last)"
      } else {
        defaultTitle = unique.first ?? "Exploration walk"
      }
    }
    if let custom = walk.customTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
      _walkTitle = State(initialValue: custom)
    } else {
      _walkTitle = State(initialValue: defaultTitle)
    }
    if let raw = walk.themeRawValue, let theme = CulturalColorTheme(rawValue: raw) {
      _selectedTheme = State(initialValue: theme)
    } else {
      _selectedTheme = State(initialValue: .blue)
    }
  }

  var body: some View {
    ObservingAudio(audio: env.audio) { isPlaying, _, currentStory, _ in
      ZStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 0) {
          // Pinned headline — stays put while the collage / timeline scroll.
          Text("Completed exploration!")
            .font(.custom(AppTextStyle.customFontPostScriptName, size: 28))
            .foregroundStyle(AppColor.Brand.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.sm)
            .accessibilityAddTraits(.isHeader)

          ScrollView {
            VStack(spacing: 24) {
              let siteInfos = visitedSiteInfos()
              SitePolaroidCollage(sites: siteInfos)

              // Tap title to edit; theme selector stays inline.
              VStack(spacing: 16) {
                editableWalkTitle

                ColorThemeSelector(selectedTheme: $selectedTheme) { _ in
                  finishEditingTitle()
                  persistExplorationEdits()
                }
                .padding(.horizontal, AppSpacing.lg)
              }

              let placesCount = max(1, walk.triggerEvents.count)
              // Future development — Exploration Badge Distance:
              // Placeholder only (places × 0.7 km). Replace with real distance
              // (sum consecutive unique site coordinates, or a recorded GPS path).
              let distanceEstimate = Double(placesCount) * 0.7
              ExplorationSummaryStats(
                placesVisitedCount: placesCount,
                distanceKm: distanceEstimate
              )
              .padding(.horizontal, AppSpacing.lg)

              let timelineEvents = uniqueTimelineEvents()
              if !timelineEvents.isEmpty {
                VStack(spacing: 0) {
                  ForEach(Array(timelineEvents.enumerated()), id: \.element.id) { index, event in
                    let isLast = index == timelineEvents.count - 1
                    let site = env.content.allSites().first(where: { $0.slug == event.siteSlug })
                    let story = site?.stories.first(where: { $0.slug == event.storySlug })
                    let isThisStoryPlaying = isPlaying && currentStory?.slug == story?.slug

                    TimelineStoryRow(
                      siteName: event.siteName,
                      storyTitle: event.storyTitle,
                      snippet: story?.transcript(for: env.settings.audioLanguage) ?? "",
                      isPlaying: isThisStoryPlaying,
                      isFirst: index == 0,
                      isLast: isLast,
                      onPlayToggle: {
                        finishEditingTitle()
                        if let story {
                          if isThisStoryPlaying {
                            env.audio.pause()
                          } else if env.audio.play(story: story) {
                            ownsPlayback = true
                          }
                        }
                      }
                    )
                  }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
              }

              // Clearance for the floating Save & Continue button
              Spacer(minLength: 100)
            }
            .padding(.top, AppSpacing.sm)
          }
          .scrollDismissesKeyboard(.immediately)
        }
        .background {
          // Tap outside the title field dismisses the keyboard without stealing
          // button taps (`cancelsTouchesInView = false`).
          ResignKeyboardTapView {
            finishEditingTitle()
          }
          .ignoresSafeArea()
        }
        .culturalTiledBackground(theme: selectedTheme, scale: 0.60)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)

        saveAndContinueButton
      }
    }
    .interactiveDismissDisabled(true)
    .onDisappear {
      stopOwnedPlayback()
    }
  }

  private var editableWalkTitle: some View {
    Group {
      if isEditingTitle {
        TextField("Title goes here...", text: $walkTitle, axis: .vertical)
          .font(.custom(AppTextStyle.customFontPostScriptName, size: 24))
          .foregroundStyle(selectedTheme.color)
          .multilineTextAlignment(.center)
          .lineLimit(1...3)
          .focused($isTitleFieldFocused)
          .onChange(of: walkTitle) { _, newValue in
            if newValue.count > maxTitleCharacters {
              walkTitle = String(newValue.prefix(maxTitleCharacters))
            }
            persistExplorationEdits()
          }
          .onSubmit {
            finishEditingTitle()
          }
          .accessibilityLabel("Exploration title")
      } else {
        Button {
          isEditingTitle = true
        } label: {
          Text(walkTitle)
            .font(.custom(AppTextStyle.customFontPostScriptName, size: 24))
            .foregroundStyle(selectedTheme.color)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Exploration title, \(walkTitle)")
        .accessibilityHint("Double tap to edit")
      }
    }
    .padding(.horizontal, AppSpacing.lg)
    .onChange(of: isEditingTitle) { _, editing in
      // Focus after the TextField is in the hierarchy.
      if editing {
        Task { @MainActor in
          isTitleFieldFocused = true
        }
      }
    }
    .onChange(of: isTitleFieldFocused) { _, focused in
      if !focused && isEditingTitle {
        finishEditingTitle()
      }
    }
  }

  private var saveAndContinueButton: some View {
    Button {
      finishEditingTitle()
      persistExplorationEdits()
      stopOwnedPlayback()
      onSaveAndContinue()
    } label: {
      ZStack {
        Image("BrushButtonBlue")
          .resizable()
          .frame(height: 60)
          .frame(maxWidth: .infinity)

        Text("Save & Continue")
          .font(.custom(AppTextStyle.customFontPostScriptName, size: 16))
          .foregroundStyle(Color(red: 254 / 255, green: 254 / 255, blue: 254 / 255))
      }
      .frame(maxWidth: .infinity)
      .frame(height: 60)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Save and continue")
    .accessibilityHint("Saves your exploration title and theme, then returns home")
    .padding(.horizontal, 24)
    .padding(.bottom, 28)
  }

  private func finishEditingTitle() {
    guard isEditingTitle || isTitleFieldFocused else { return }
    isTitleFieldFocused = false
    isEditingTitle = false
    persistExplorationEdits()
  }

  private func persistExplorationEdits() {
    env.history.updateExploration(
      walk: walk,
      customTitle: walkTitle,
      themeRawValue: selectedTheme.rawValue
    )
  }

  private func stopOwnedPlayback() {
    guard ownsPlayback else { return }
    env.audio.stop()
    ownsPlayback = false
  }

  /// Chronological unique sites for the timeline — repeats of the same site keep the earliest trigger.
  private func uniqueTimelineEvents() -> [TriggerEvent] {
    let sorted = walk.triggerEvents.sorted { $0.firedAt < $1.firedAt }
    var seen = Set<String>()
    var unique: [TriggerEvent] = []
    for event in sorted {
      guard !seen.contains(event.siteSlug) else { continue }
      seen.insert(event.siteSlug)
      unique.append(event)
    }
    return unique
  }

  private func visitedSiteInfos() -> [(name: String, imageAssetName: String?)] {
    let events = walk.triggerEvents.sorted { $0.firedAt < $1.firedAt }
    var result: [(name: String, imageAssetName: String?)] = []
    var seen = Set<String>()

    for event in events {
      if !seen.contains(event.siteSlug) {
        seen.insert(event.siteSlug)
        let site = env.content.allSites().first(where: { $0.slug == event.siteSlug })
        let img = site?.thumbnailAssetName ?? "\(event.siteSlug).jpg"
        result.append((name: event.siteName, imageAssetName: img))
      }
    }

    return result
  }
}

// MARK: - Tap outside to resign keyboard

/// Installs a non-cancelling tap on the host superview so taps outside a text field
/// dismiss the keyboard without blocking buttons or the title field itself.
private struct ResignKeyboardTapView: UIViewRepresentable {
  var onTap: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onTap: onTap)
  }

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.isUserInteractionEnabled = false
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.onTap = onTap
    context.coordinator.attachIfNeeded(from: uiView)
  }

  static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
    coordinator.detach()
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    var onTap: () -> Void
    private weak var hostView: UIView?
    private var tapGesture: UITapGestureRecognizer?

    init(onTap: @escaping () -> Void) {
      self.onTap = onTap
    }

    func attachIfNeeded(from probe: UIView) {
      guard tapGesture == nil else { return }
      // Wait a turn so the representable is in the hierarchy and has a superview.
      DispatchQueue.main.async { [weak self, weak probe] in
        guard let self, let probe else { return }
        guard let host = probe.superview ?? probe.window else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        host.addGestureRecognizer(tap)
        self.tapGesture = tap
        self.hostView = host
      }
    }

    func detach() {
      if let tapGesture, let hostView {
        hostView.removeGestureRecognizer(tapGesture)
      }
      tapGesture = nil
      hostView = nil
    }

    @objc func handleTap() {
      onTap()
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldReceive touch: UITouch
    ) -> Bool {
      var view = touch.view
      while let current = view {
        if current is UITextField || current is UITextView {
          return false
        }
        view = current.superview
      }
      return true
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      true
    }
  }
}

// MARK: - Previews

#Preview("End View") {
  let env = AppEnvironment()
  let walk = Walk(startedAt: .now)
  EndView(walk: walk, onSaveAndContinue: {})
    .environment(env)
}
