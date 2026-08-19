import Foundation
import Observation

/// The consent gate (Slice 11 + 11.5). Owns prompting, briefly pausing the current story only for
/// the spoken prompt line, and the three answers (play / dismiss / queue). List storage lives on
/// `StoryQueue`.
@Observable
final class ConsentNarrationCoordinator: NarrationCoordinator {
  private(set) var state: NarrationState = .idle
  private(set) var pendingPrompt: PendingPrompt?
  /// Seconds left on the post-speech dismiss countdown; nil when not counting.
  private(set) var dismissCountdownSeconds: Int?

  /// Fires when a prompt resolves (or a busy trigger is silently queued).
  var onOutcome: ((PendingPrompt, PromptOutcome) -> Void)?

  /// Exposed so tests await the dismiss countdown deterministically.
  private(set) var timeoutTask: Task<Void, Never>?

  // `var` only because callbacks are assigned below; references are never reassigned for ownership.
  private var audio: any AudioPlayerService
  private var promptVoice: any PromptVoice
  private let remoteControl: any ConsentRemoteControl
  private let storyQueue: any StoryQueue
  private let dismissCountdown: Duration

  private var pendingSite: Site?
  private var pendingStory: Story?
  /// True only while TTS is speaking over a paused story. Cleared when speech ends (resume) or
  /// when the user answers during speech.
  private var pausedForSpokenPrompt = false

  init(
    audio: any AudioPlayerService,
    promptVoice: any PromptVoice,
    remoteControl: any ConsentRemoteControl,
    storyQueue: any StoryQueue,
    dismissCountdown: Duration = .seconds(AppConfig.dismissCountdownSeconds)
  ) {
    self.audio = audio
    self.promptVoice = promptVoice
    self.remoteControl = remoteControl
    self.storyQueue = storyQueue
    self.dismissCountdown = dismissCountdown

    self.audio.onPlaybackFinished = { [weak self] in
      self?.playbackDidFinish()
    }
    self.promptVoice.onFinished = { [weak self] in
      self?.spokenPromptDidFinish()
    }
  }

  func handleTrigger(site: Site, story: Story) {
    // Already asking — don't stack prompts; keep the story for later.
    if state == .prompting {
      enqueueSilently(site: site, story: story)
      return
    }

    if state == .playing {
      audio.pause()
      pausedForSpokenPrompt = true
    } else {
      pausedForSpokenPrompt = false
    }

    beginPrompt(site: site, story: story)
  }

  func accept(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID,
      let story = pendingStory
    else { return }
    // Play now replaces whatever was underneath — do not resume it.
    pausedForSpokenPrompt = false
    endPrompt()
    state = .playing
    audio.play(story: story)
    onOutcome?(prompt, .played)
  }

  func dismiss(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID else { return }
    endPrompt()
    onOutcome?(prompt, .dismissed)
    settleAfterPromptResolved()
  }

  func queue(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID,
      let site = pendingSite, let story = pendingStory
    else { return }
    storyQueue.enqueue(site: site, story: story)
    endPrompt()
    onOutcome?(prompt, .queued)
    settleAfterPromptResolved()
  }

  func playbackDidFinish() {
    // Underlying story can finish while a prompt is still open (A resumed under B's ask).
    // Leave the prompt up; settleAfterPromptResolved / accept handle what happens next.
    if state == .prompting { return }

    guard state == .playing else { return }
    if let next = storyQueue.popNext() {
      audio.play(story: next)
    } else {
      state = .idle
    }
  }

  // MARK: - Private

  private func beginPrompt(site: Site, story: Story) {
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
    pendingSite = site
    pendingStory = story
    state = .prompting
    dismissCountdownSeconds = nil

    let id = prompt.id
    remoteControl.arm(title: story.title) { [weak self] in
      self?.accept(promptID: id)
    }
    promptVoice.speak(spoken)
    // Resume + dismiss countdown start in `spokenPromptDidFinish`.
  }

  private func enqueueSilently(site: Site, story: Story) {
    storyQueue.enqueue(site: site, story: story)
    let prompt = PendingPrompt(
      id: UUID(),
      siteSlug: site.slug,
      siteName: site.name,
      storySlug: story.slug,
      storyTitle: story.title,
      directionPhrase: nil,
      spokenText: ApproachPrompt.text(siteName: site.name, directionPhrase: nil)
    )
    onOutcome?(prompt, .queued)
  }

  private func spokenPromptDidFinish() {
    guard state == .prompting, let prompt = pendingPrompt else { return }

    // Site A only stays paused for the spoken line — resume as soon as TTS ends, even if she
    // hasn't answered yet. The dismiss countdown runs while A continues underneath.
    if pausedForSpokenPrompt {
      pausedForSpokenPrompt = false
      audio.resume()
    }

    startDismissCountdown(promptID: prompt.id)
  }

  private func startDismissCountdown(promptID: UUID) {
    timeoutTask?.cancel()
    let wholeSeconds = Int(dismissCountdown.components.seconds)

    // Sub-second injections are for unit tests — one sleep, then timeout.
    if wholeSeconds == 0 {
      dismissCountdownSeconds = 1
      timeoutTask = Task { [weak self, dismissCountdown] in
        try? await Task.sleep(for: dismissCountdown)
        guard !Task.isCancelled else { return }
        self?.dismissCountdownSeconds = 0
        self?.resolveTimeout(promptID: promptID)
      }
      return
    }

    dismissCountdownSeconds = wholeSeconds
    timeoutTask = Task { [weak self] in
      var remaining = wholeSeconds
      while remaining > 0 {
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
        remaining -= 1
        self?.dismissCountdownSeconds = remaining
      }
      guard !Task.isCancelled else { return }
      self?.resolveTimeout(promptID: promptID)
    }
  }

  private func resolveTimeout(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID else { return }
    endPrompt()
    onOutcome?(prompt, .timedOut)
    settleAfterPromptResolved()
  }

  /// After dismiss / queue / timeout: keep A going if it already resumed (or still needs resume
  /// because she answered mid-TTS); otherwise idle or drain the queue.
  private func settleAfterPromptResolved() {
    if pausedForSpokenPrompt {
      pausedForSpokenPrompt = false
      audio.resume()
      state = .playing
      return
    }
    if audio.isPlaying {
      state = .playing
      return
    }
    if let next = storyQueue.popNext() {
      state = .playing
      audio.play(story: next)
    } else {
      state = .idle
    }
  }

  private func endPrompt() {
    promptVoice.stop()
    remoteControl.disarm()
    timeoutTask?.cancel()
    timeoutTask = nil
    dismissCountdownSeconds = nil
    pendingPrompt = nil
    pendingSite = nil
    pendingStory = nil
  }
}
