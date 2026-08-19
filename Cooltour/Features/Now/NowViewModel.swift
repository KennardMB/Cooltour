import Foundation

/// Drives the Now screen. Holds no audio/proximity logic of its own — it only reads the
/// existing services and exposes intent-named methods, so `NowView` never touches
/// `AppEnvironment` directly.
@Observable
final class NowViewModel {
  /// Exposed directly (not wrapped) so the view can `@Bindable` into it for the auto-play
  /// toggle — `SettingsStore` is already the single source of truth Settings writes to.
  let settings: SettingsStore

  private let audio: any AudioPlayerService
  private let proximity: any ProximityEngine
  private let content: any ContentStore

  /// `AudioPlayerService.currentStory` goes nil the moment a story finishes or is stopped,
  /// so the Now card would otherwise disappear right when the user is most likely to want
  /// to glance back at what just played. This is what lets the card say "last played".
  private(set) var lastPlayedStory: Story?

  init(environment: AppEnvironment) {
    self.audio = environment.audio
    self.proximity = environment.proximity
    self.content = environment.content
    self.settings = environment.settings
  }

  // MARK: - Now card

  var displayedStory: Story? { audio.currentStory ?? lastPlayedStory }
  var isPlaying: Bool { audio.isPlaying }
  var isLoading: Bool { audio.isLoading }
  var progress: Double { audio.progress }

  var displayedDistanceMeters: Double? {
    guard let slug = displayedStory?.site?.slug else { return nil }
    return proximity.nearbySites.first { $0.id == slug }?.distanceMeters
  }

  func snippet(for story: Story, limit: Int = 140) -> String {
    guard story.transcript.count > limit else { return story.transcript }
    return String(story.transcript.prefix(limit)) + "…"
  }

  // MARK: - Status line

  var statusText: String {
    guard proximity.isListening else { return "Nothing nearby yet" }
    let nearby = proximity.nearbySites.filter(\.isInsideRadius).count
    guard nearby > 0 else { return "Listening for nearby stories" }
    return nearby == 1 ? "1 story nearby" : "\(nearby) stories nearby"
  }

  // MARK: - Teaser (shown when nothing has played yet)

  var nearestSite: NearbySite? { proximity.nearbySites.first }

  // MARK: - Today's walk feed

  var todaysEvents: [TriggerEvent] { proximity.recentEvents }

  // MARK: - Intents

  func togglePlayback() {
    if audio.isPlaying {
      audio.pause()
    } else if audio.currentStory != nil {
      audio.resume()
    } else if let story = lastPlayedStory {
      play(story)
    }
  }

  func selectSpeed(_ speed: Double) {
    settings.defaultPlaybackSpeed = speed
    audio.setRate(Float(speed))
  }

  func toggleAutoPlay() {
    settings.autoPlay.toggle()
  }

  /// Replays a story from the feed. Manual playback also covers testing until Slice 3's
  /// proximity triggers are exercised on a real walk.
  func replay(_ event: TriggerEvent) {
    guard
      let site = content.allSites().first(where: { $0.slug == event.siteSlug }),
      let story = site.stories.first(where: { $0.slug == event.storySlug })
    else { return }
    play(story)
  }

  func playNearestSite() {
    guard
      let nearby = nearestSite,
      let site = content.allSites().first(where: { $0.slug == nearby.id }),
      let story = site.stories.first
    else { return }
    play(story)
  }

  private func play(_ story: Story) {
    lastPlayedStory = story
    audio.play(story: story)
  }
}
