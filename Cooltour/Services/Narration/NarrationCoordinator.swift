import Foundation

/// Sits between the proximity engine and the audio player: proximity decides WHERE, the
/// coordinator decides WHETHER and WHEN, the player decides HOW.
///
/// It's a service of its own — not a method on `AudioPlayerService` — because the interesting
/// cases (an ignored prompt, two answer paths racing, a trigger arriving mid-story) have nothing
/// to do with audio and shouldn't need an `AVAudioSession` to test. It also keeps `audio.isPlaying`
/// meaning exactly "a story is playing", and keeps the answer *rules* reusable on the Watch, where
/// the answer *input* is a wrist tap rather than an AirPod stem.
@MainActor
protocol NarrationCoordinator: AnyObject, Observable {
  var state: NarrationState { get }
  var pendingPrompt: PendingPrompt? { get }
  /// Seconds left on the post-speech dismiss countdown; nil when not counting (Slice 11.5).
  var dismissCountdownSeconds: Int? { get }

  /// A site came into range. The coordinator decides whether to prompt, ignore it (busy), or
  /// queue it. Wired to `proximity.onTrigger` in `AppEnvironment`.
  func handleTrigger(site: Site, story: Story)

  /// "Play now." The stem, the notification action, and the on-screen button all land here.
  /// `promptID` guards a stale answer from resolving a prompt that has already moved on.
  func accept(promptID: UUID)

  /// "Dismiss." Same three surfaces, same staleness guard. No story plays.
  func dismiss(promptID: UUID)

  /// "Add to queue." Plays nothing now; the queue auto-plays it after the current story finishes.
  func queue(promptID: UUID)
}
