import Foundation
import Observation

/// The consent gate (Slice 11 + 11.5 + Watch 18/20). Owns prompting, briefly pausing the current
/// story only for the spoken prompt line, the three answers (play / dismiss / queue), and
/// wayfinding arm/clear. List storage lives on `StoryQueue`.
@Observable
final class ConsentNarrationCoordinator: NarrationCoordinator {
  private(set) var state: NarrationState = .idle
  private(set) var pendingPrompt: PendingPrompt?
  /// Seconds left on the post-speech dismiss countdown; nil when not counting.
  private(set) var dismissCountdownSeconds: Int?
  private(set) var wayfindingTarget: WayfindingTarget?

  /// Fires when a prompt resolves (or a busy trigger is silently queued).
  var onOutcome: ((PendingPrompt, PromptOutcome) -> Void)?
  /// Fires whenever `wayfindingTarget` is set or cleared so the Watch bridge can push immediately.
  var onWayfindingTargetChange: ((WayfindingTarget?) -> Void)?

  /// Exposed so tests await the dismiss countdown deterministically.
  private(set) var timeoutTask: Task<Void, Never>?

  // `var` only because callbacks are assigned below; references are never reassigned for ownership.
  private var audio: any AudioPlayerService
  private var promptVoice: any PromptVoice
  private let approachChime: any ApproachChimePlayer
  private let remoteControl: any ConsentRemoteControl
  private let storyQueue: any StoryQueue
  private let notifications: (any NotificationService)?
  private let settings: SettingsStore
  private let dismissCountdown: Duration

  private var pendingSite: Site?
  private var pendingStory: Story?
  /// Site for the story currently handed to the player — used to arm wayfinding on start.
  private var playingSite: Site?
  /// True only while TTS is speaking over a paused story. Cleared when speech ends (resume) or
  /// when the user answers during speech.
  private var pausedForSpokenPrompt = false

  init(
    audio: any AudioPlayerService,
    promptVoice: any PromptVoice,
    approachChime: any ApproachChimePlayer = MockApproachChimePlayer(),
    remoteControl: any ConsentRemoteControl,
    storyQueue: any StoryQueue,
    notifications: (any NotificationService)? = nil,
    settings: SettingsStore = SettingsStore(),
    dismissCountdown: Duration = .seconds(AppConfig.dismissCountdownSeconds)
  ) {
    self.audio = audio
    self.promptVoice = promptVoice
    self.approachChime = approachChime
    self.remoteControl = remoteControl
    self.storyQueue = storyQueue
    self.notifications = notifications
    self.settings = settings
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

    if state == .playing && audio.isPlaying {
      audio.pause()
      pausedForSpokenPrompt = true
    } else {
      pausedForSpokenPrompt = false
    }

    beginPrompt(site: site, story: story)
  }

  func accept(promptID: UUID) {
    guard state == .prompting, let prompt = pendingPrompt, prompt.id == promptID,
      let site = pendingSite, let story = pendingStory
    else { return }
    // Play now replaces whatever was underneath — do not resume it.
    pausedForSpokenPrompt = false
    endPrompt()
    if startPlayback(story, site: site) {
      onOutcome?(prompt, .played)
    } else {
      // Chosen language has no audio — silence, treat as a dismiss for history.
      onOutcome?(prompt, .dismissed)
      settleAfterPromptResolved()
    }
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

  func cancelSession() {
    let keepPlaying = audio.isPlaying || audio.currentStory != nil
    endPrompt()
    pausedForSpokenPrompt = false
    // Walking-off clears consent + arrow; an already-playing story can finish in the ear.
    setWayfinding(nil)
    if !keepPlaying {
      playingSite = nil
      state = .idle
    } else {
      state = .playing
    }
  }

  func clearWayfindingTarget() {
    setWayfinding(nil)
  }

  func playbackDidFinish() {
    // Underlying story can finish while a prompt is still open (A resumed under B's ask).
    // Leave the prompt up; settleAfterPromptResolved / accept handle what happens next.
    if state == .prompting { return }

    guard state == .playing else { return }
    if let next = storyQueue.popNext() {
      let site = next.site
      _ = startPlayback(next, site: site)
    } else {
      playingSite = nil
      setWayfinding(nil)
      state = .idle
    }
  }

  // MARK: - Private

  private func beginPrompt(site: Site, story: Story) {
    let directionPhrase: String? = nil
    let languageCode = settings.resolvedLanguageCode
    let spoken = ApproachPrompt.text(
      siteName: site.name,
      directionPhrase: directionPhrase,
      languageCode: languageCode
    )
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
    // Only arm remote control (AirPod stem press) if no story was active.
    // When a story is already active (playing or paused), media controls belong to that story.
    if !pausedForSpokenPrompt && audio.currentStory == nil {
      remoteControl.arm(title: story.title) { [weak self] in
        self?.accept(promptID: id)
      }
    }
    notifications?.postPrompt(prompt)
    approachChime.play { [weak self] in
      self?.promptVoice.speak(spoken, languageCode: languageCode)
    }
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
      spokenText: ApproachPrompt.text(
        siteName: site.name,
        directionPhrase: nil,
        languageCode: settings.resolvedLanguageCode
      )
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
    if audio.isPlaying || audio.currentStory != nil {
      state = .playing
      return
    }
    if let next = storyQueue.popNext() {
      _ = startPlayback(next, site: next.site)
    } else {
      playingSite = nil
      setWayfinding(nil)
      state = .idle
    }
  }

  /// Starts story audio or advances past unavailable assets. Returns whether something is playing.
  /// Arms wayfinding in the same step so A→B never publishes a nil target between sites.
  @discardableResult
  private func startPlayback(_ story: Story, site: Site?) -> Bool {
    if audio.play(story: story) {
      state = .playing
      playingSite = site ?? story.site
      if let armed = playingSite {
        setWayfinding(
          WayfindingPolicy.target(
            siteSlug: armed.slug,
            siteName: armed.name,
            latitude: armed.latitude,
            longitude: armed.longitude,
            triggerRadiusMeters: armed.triggerRadiusMeters
          )
        )
      } else {
        setWayfinding(nil)
      }
      return true
    }
    // Missing recording for the selected language — try the next queued story, else idle.
    if let next = storyQueue.popNext() {
      return startPlayback(next, site: next.site)
    }
    playingSite = nil
    setWayfinding(nil)
    state = .idle
    return false
  }

  private func setWayfinding(_ target: WayfindingTarget?) {
    guard wayfindingTarget != target else { return }
    wayfindingTarget = target
    onWayfindingTargetChange?(target)
  }

  private func endPrompt() {
    if let id = pendingPrompt?.id {
      notifications?.withdrawPrompt(id: id)
    }
    approachChime.stop()
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
