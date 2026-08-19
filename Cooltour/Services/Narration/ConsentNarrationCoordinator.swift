import Foundation
import Observation

/// The real consent gate (Slice 11b). Owns the `idle → prompting → playing → idle` machine: a
/// trigger raises a spoken prompt and arms the stem, an answer plays the story, and no answer within
/// the timeout leaves silence. Everything an `AVAudioSession` would make hard to test — an ignored
/// prompt, a stale answer, a trigger arriving mid-story — lives here behind injected mocks.
@Observable
final class ConsentNarrationCoordinator: NarrationCoordinator {
  private(set) var state: NarrationState = .idle
  private(set) var pendingPrompt: PendingPrompt?

  /// Fires when a prompt resolves, with the prompt and how it ended. `AppEnvironment` forwards this
  /// to history at go-live (Slice 11 "G").
  var onOutcome: ((PendingPrompt, PromptOutcome) -> Void)?

  /// Exposed so tests await the timeout deterministically (by injecting a tiny `Duration`) instead
  /// of sleeping the real 20 seconds.
  private(set) var timeoutTask: Task<Void, Never>?

  // `var` only because `onPlaybackFinished` is set below; the reference is never reassigned.
  private var audio: any AudioPlayerService
  private let promptVoice: any PromptVoice
  private let remoteControl: any ConsentRemoteControl
  private let consentTimeout: Duration

  /// The pending prompt's story, held privately so `PendingPrompt` stays free of SwiftData.
  private var pendingStory: Story?

  init(
    audio: any AudioPlayerService,
    promptVoice: any PromptVoice,
    remoteControl: any ConsentRemoteControl,
    consentTimeout: Duration = .seconds(AppConfig.consentTimeoutSeconds)
  ) {
    self.audio = audio
    self.promptVoice = promptVoice
    self.remoteControl = remoteControl
    self.consentTimeout = consentTimeout

    // Return to idle when the story we launched finishes on its own. Safe even for playback the
    // coordinator didn't start: `playbackDidFinish` no-ops unless we're in `.playing`.
    self.audio.onPlaybackFinished = { [weak self] in
      self?.playbackDidFinish()
    }
  }

  func handleTrigger(site: Site, story: Story) {
    // One ask at a time. A trigger arriving mid-prompt or mid-story is dropped this slice and
    // queued in Slice 11.5 — prompting over a playing story would talk across it.
    guard state == .idle else { return }

    // Direction is stubbed until Slice 12; nil omits the phrase rather than guessing.
    let directionPhrase: String? = nil
    let spoken = ApproachPrompt.text(siteName: site.name, directionPhrase: directionPhrase)
    let prompt = PendingPrompt(
      id: UUID(),
      siteSlug: site.slug,
      siteName: site.name,
      storySlug: story.slug,
      storyTitle: story.title,
      directionPhrase: directionPhrase,
      spokenText: spoken
    )

    pendingPrompt = prompt
    pendingStory = story
    state = .prompting

    // The stem answers "play now" without the phone leaving a pocket — armed only now, disarmed
    // the instant the prompt resolves.
    let id = prompt.id
    remoteControl.arm(title: story.title) { [weak self] in
      self?.accept(promptID: id)
    }
    promptVoice.speak(spoken)

    // No answer means silence.
    timeoutTask = Task { [weak self, consentTimeout] in
      try? await Task.sleep(for: consentTimeout)
      guard !Task.isCancelled else { return }
      self?.resolveTimeout(promptID: id)
    }
  }

  func accept(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID,
      let story = pendingStory
    else { return }
    endPrompt()
    state = .playing
    audio.play(story: story)
    onOutcome?(prompt, .played)
  }

  func dismiss(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID else { return }
    endPrompt()
    state = .idle
    onOutcome?(prompt, .dismissed)
  }

  /// Wired to `AudioPlayerService.onPlaybackFinished` in the real init (Slice 11 "F") so the machine
  /// returns to idle when the story ends and can prompt again. Internal rather than in the protocol:
  /// it's an implementation detail of this coordinator, exercised directly in tests.
  func playbackDidFinish() {
    guard state == .playing else { return }
    state = .idle
  }

  private func resolveTimeout(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID else { return }
    endPrompt()
    state = .idle
    onOutcome?(prompt, .timedOut)
  }

  /// Shared teardown for every prompt exit: cut the voice, hand the stem back, cancel the timeout,
  /// and clear the pending prompt and its story. The caller sets the next state (and, on accept,
  /// captures the story first).
  private func endPrompt() {
    promptVoice.stop()
    remoteControl.disarm()
    timeoutTask?.cancel()
    timeoutTask = nil
    pendingPrompt = nil
    pendingStory = nil
  }
}
