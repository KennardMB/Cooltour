import SwiftData
import SwiftUI

// MARK: - My Exploration Details Screen (Figma Node 204:2091 & 204:2356)

struct MyExplorationDetailsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(AppEnvironment.self) private var env
  let walk: Walk
  
  @State private var walkTitle: String
  @State private var selectedTheme: CulturalColorTheme = .blue
  @State private var isEditingTitle: Bool = false
  /// Replay on this screen is view-scoped. If we started playback, leaving must stop it
  /// so the story does not keep playing in the global player / miniplayer.
  @State private var ownsPlayback: Bool = false
  
  init(walk: Walk) {
    self.walk = walk
    // Prefer a user-edited title; otherwise first–last visited site ("SiteA - SiteD").
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
    ObservingAudio(audio: env.audio) { isPlaying, isLoading, currentStory, progress in
      ZStack {
        VStack(alignment: .leading, spacing: 0) {
          // 1. Top Navigation Bar (Back + Edit Buttons)
          HStack {
            Button {
              stopOwnedPlayback()
              dismiss()
            } label: {
              AppIcon(.chevronLeft, size: 24)
                .padding(AppSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            
            Spacer()
            
            Button {
              isEditingTitle = true
            } label: {
              Text("Edit")
                .appFont(.heading3, color: AppColor.Text.primary)
                .padding(AppSpacing.sm)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit exploration title")
          }
          .padding(.horizontal, AppSpacing.lg)
          .padding(.top, AppSpacing.sm)
          
          // 2. Scrollable Details Body
          ScrollView {
            VStack(spacing: 24) {
              // A. Polaroid Photo Collage Stack
              let siteInfos = visitedSiteInfos()
              SitePolaroidCollage(sites: siteInfos)
                .padding(.top, AppSpacing.sm)
              
              // B. Exploration Custom Walk Title
              Text(walkTitle)
                .font(.custom(AppTextStyle.customFontPostScriptName, size: 24))
                .foregroundStyle(selectedTheme.color)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, AppSpacing.lg)
              
              // C. Exploration Summary Badges
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
              
              // D. Audio Queue Timeline — one row per site, earliest trigger only.
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
              
              Spacer(minLength: 40)
            }
            .padding(.top, AppSpacing.sm)
          }
        }
        .culturalTiledBackground(theme: selectedTheme, scale: 0.60)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        
        // 3. Custom Edit Exploration Modal (Figma Node 204:2356)
        if isEditingTitle {
          EditExplorationModal(
            isPresented: $isEditingTitle,
            title: $walkTitle,
            theme: $selectedTheme,
            onSave: { newTitle, newTheme in
              walkTitle = newTitle
              selectedTheme = newTheme
              env.history.updateExploration(
                walk: walk,
                customTitle: newTitle,
                themeRawValue: newTheme.rawValue
              )
            }
          )
        }
      }
    }
    .onDisappear {
      stopOwnedPlayback()
    }
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
    
    if result.isEmpty {
      result.append((name: "Bajra Sandhi", imageAssetName: "monumen-perjuangan-rakyat-bali.jpg"))
      result.append((name: "Prasasti Blanjong", imageAssetName: "prasasti-blanjong.jpg"))
      result.append((name: "Museum Le Mayeur", imageAssetName: "museum-le-mayeur.jpg"))
    }
    
    return result
  }
}

// MARK: - Timeline Story Row Component

private struct TimelineStoryRow: View {
  let siteName: String
  let storyTitle: String
  let snippet: String
  let isPlaying: Bool
  let isFirst: Bool
  let isLast: Bool
  let onPlayToggle: () -> Void
  
  private let nodeSize: CGFloat = 18
  private let nodeTopInset: CGFloat = 24
  
  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      // Timeline indicator: bridge top inset into the node, then fill down to the next row.
      VStack(spacing: 0) {
        if isFirst {
          Color.clear.frame(height: nodeTopInset)
        } else {
          Rectangle()
            .fill(AppColor.Brand.primary.opacity(0.35))
            .frame(width: 2, height: nodeTopInset)
        }
        
        Circle()
          .fill(isPlaying ? AppColor.Brand.primary : AppColor.Background.pure)
          .frame(width: nodeSize, height: nodeSize)
          .overlay(
            Circle()
              .strokeBorder(AppColor.Brand.primary, lineWidth: isPlaying ? 0 : 2)
          )
        
        if !isLast {
          // Spacer takes remaining row height so the rail reaches the next node.
          Spacer(minLength: 0)
            .frame(width: 2)
            .overlay {
              Rectangle()
                .fill(AppColor.Brand.primary.opacity(0.35))
            }
        }
      }
      .frame(width: 24)
      .frame(maxHeight: .infinity, alignment: .top)
      
      // Story Card
      HStack(alignment: .center, spacing: AppSpacing.sm) {
        VStack(alignment: .leading, spacing: 4) {
          Text(siteName)
            .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
            .foregroundStyle(isPlaying ? AppColor.Brand.primary : AppColor.Text.primary)
            .lineLimit(1)
          
          if !snippet.isEmpty {
            Text(snippet)
              .appFont(.label, color: AppColor.Text.secondary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
          }
        }
        
        Spacer(minLength: 8)
        
        Button {
          onPlayToggle()
        } label: {
          AppIcon(isPlaying ? .pause : .play, size: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause story" : "Play story")
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .background(AppColor.Background.pure)
      .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
      .overlay(
        RoundedRectangle(cornerRadius: AppRadius.standard)
          .strokeBorder(
            isPlaying ? AppColor.Brand.primary : AppColor.Background.border,
            lineWidth: isPlaying ? 2 : 1
          )
      )
      .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
      .padding(.bottom, 12)
    }
  }
}

// MARK: - Previews

#Preview("My Exploration Details Screen") {
  let env = AppEnvironment()
  let walk = Walk(startedAt: .now)
  NavigationStack {
    MyExplorationDetailsView(walk: walk)
      .environment(env)
  }
}
