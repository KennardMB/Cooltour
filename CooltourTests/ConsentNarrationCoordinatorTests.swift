import Testing

@testable import Cooltour

@MainActor
struct ConsentNarrationCoordinatorTests {

  // MARK: - Fixtures

  private func makeSite(slug: String = "pura-maospahit", name: String = "Pura Maospahit") -> Site {
    Site(
      slug: slug,
      name: name,
      districtName: "Denpasar",
      latitude: -8.6,
      longitude: 115.2,
      triggerRadiusMeters: 60,
      headingRequired: false
    )
  }

  private func makeStory(slug: String = "pura-maospahit-01", title: String = "The Split Gate") -> Story {
    Story(
      slug: slug,
      title: title,
      audioAssetName: "\(slug).m4a",
      transcript: "…",
      durationSeconds: 42
    )
  }

  private func makeCoordinator(
    countdown: Duration = .seconds(60),
    chime: MockApproachChimePlayer = MockApproachChimePlayer()
  ) -> (
    ConsentNarrationCoordinator, MockAudioPlayerService, MockPromptVoice,
    MockApproachChimePlayer, MockConsentRemoteControl,
    MockStoryQueue
  ) {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let queue = MockStoryQueue()
    let settings = SettingsStore()
    settings.appLanguage = .english
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      approachChime: chime,
      remoteControl: remote,
      storyQueue: queue,
      settings: settings,
      dismissCountdown: countdown
    )
    return (coordinator, audio, voice, chime, remote, queue)
  }

  // MARK: - Prompting

  @Test func triggerPromptsSpeaksAndArmsTheStem() {
    let (coordinator, audio, voice, _, remote, _) = makeCoordinator()

    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt?.siteSlug == "pura-maospahit")
    #expect(voice.lastSpoken == "You're approaching Pura Maospahit. Press play to hear it.")
    #expect(remote.isArmed)
    #expect(remote.armedTitle == "The Split Gate")
    #expect(!audio.isPlaying)
  }

  @Test func triggerPlaysChimeBeforeSpeaking() {
    let chime = MockApproachChimePlayer()
    chime.autoFinish = false
    let (coordinator, _, voice, _, _, _) = makeCoordinator(chime: chime)

    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    #expect(chime.playCount == 1)
    #expect(voice.lastSpoken == nil)

    chime.finishPlaying()

    #expect(voice.lastSpoken == "You're approaching Pura Maospahit. Press play to hear it.")
  }

  @Test func acceptDuringChimeStopsEarcon() {
    let chime = MockApproachChimePlayer()
    chime.autoFinish = false
    let (coordinator, _, _, _, _, _) = makeCoordinator(chime: chime)
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let id = coordinator.pendingPrompt!.id

    coordinator.accept(promptID: id)

    #expect(chime.stopCount == 1)
  }

  @Test func triggerUsesAppLanguageForSpokenPrompt() {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let queue = MockStoryQueue()
    let settings = SettingsStore()
    settings.appLanguage = .indonesian
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      storyQueue: queue,
      settings: settings
    )

    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    #expect(
      voice.lastSpoken
        == "Anda mendekati Pura Maospahit. Tekan putar untuk mendengarkannya."
    )
    #expect(coordinator.pendingPrompt?.spokenText == voice.lastSpoken)
  }

  // MARK: - Accept

  @Test func acceptPlaysTheStoryAndHandsBackTheStem() {
    let (coordinator, audio, voice, _, remote, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let id = coordinator.pendingPrompt!.id

    coordinator.accept(promptID: id)

    #expect(coordinator.state == .playing)
    #expect(audio.currentStory?.slug == "pura-maospahit-01")
    #expect(!remote.isArmed)
    #expect(coordinator.pendingPrompt == nil)
    #expect(voice.stopCount == 1)
  }

  @Test func stemPressPlaysTheStory() {
    let (coordinator, audio, _, _, remote, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    remote.simulateStemPress()

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
  }

  // MARK: - Dismiss

  @Test func dismissPlaysNothing() {
    let (coordinator, audio, _, _, remote, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let id = coordinator.pendingPrompt!.id

    coordinator.dismiss(promptID: id)

    #expect(coordinator.state == .idle)
    #expect(audio.currentStory == nil)
    #expect(!remote.isArmed)
  }

  // MARK: - Timeout

  @Test func noAnswerTimesOutIntoSilence() async {
    var outcomes: [PromptOutcome] = []
    let audio = MockAudioPlayerService()
    let settings = SettingsStore()
    settings.appLanguage = .english
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: MockPromptVoice(),
      remoteControl: MockConsentRemoteControl(),
      storyQueue: MockStoryQueue(),
      settings: settings,
      dismissCountdown: .milliseconds(1)
    )
    coordinator.onOutcome = { _, outcome in outcomes.append(outcome) }

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    await coordinator.timeoutTask?.value

    #expect(coordinator.state == .idle)
    #expect(audio.currentStory == nil)
    #expect(outcomes == [.timedOut])
  }

  // MARK: - Idempotency and staleness

  @Test func answeringTwiceResolvesOnlyOnce() {
    let (coordinator, _, _, _, _, _) = makeCoordinator()
    var outcomes: [PromptOutcome] = []
    coordinator.onOutcome = { _, outcome in outcomes.append(outcome) }
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let id = coordinator.pendingPrompt!.id

    coordinator.accept(promptID: id)
    coordinator.accept(promptID: id)
    coordinator.dismiss(promptID: id)

    #expect(coordinator.state == .playing)
    #expect(outcomes == [.played])
  }

  @Test func staleAnswerCannotResolveTheCurrentPrompt() {
    let (coordinator, audio, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let staleID = coordinator.pendingPrompt!.id
    coordinator.dismiss(promptID: staleID)

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    coordinator.accept(promptID: staleID)

    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt?.siteSlug == "b")
    #expect(audio.currentStory == nil)
  }

  // MARK: - Queue (Slice 11.5)

  @Test func triggerWhilePromptingEnqueuesSilently() {
    let (coordinator, _, _, _, _, queue) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let firstID = coordinator.pendingPrompt!.id

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))

    #expect(coordinator.pendingPrompt?.id == firstID)
    #expect(queue.items.map(\.storySlug) == ["b-1"])
  }

  @Test func playingThenTriggerPausesDuringSpeechThenResumes() {
    let (coordinator, audio, voice, _, _, _) = makeCoordinator()
    voice.autoFinish = false

    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(audio.isPlaying)

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    #expect(coordinator.state == .prompting)
    #expect(!audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")

    voice.finishSpeaking()

    #expect(audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(coordinator.state == .prompting)
  }

  @Test func queueKeepsUnderlyingStoryPlaying() {
    let (coordinator, audio, _, _, _, queue) = makeCoordinator()
    var outcomes: [PromptOutcome] = []
    coordinator.onOutcome = { _, outcome in outcomes.append(outcome) }

    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    // autoFinish already resumed A under the open prompt
    #expect(audio.isPlaying)

    coordinator.queue(promptID: coordinator.pendingPrompt!.id)

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(queue.items.map(\.storySlug) == ["b-1"])
    #expect(outcomes.last == .queued)
  }

  @Test func dismissKeepsUnderlyingStoryPlaying() {
    let (coordinator, audio, _, _, _, queue) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))

    coordinator.dismiss(promptID: coordinator.pendingPrompt!.id)

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(queue.items.isEmpty)
  }

  @Test func finishingStoryAutoPlaysQueuedNext() {
    let (coordinator, audio, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    coordinator.queue(promptID: coordinator.pendingPrompt!.id)

    audio.simulatePlaybackFinished()

    #expect(coordinator.state == .playing)
    #expect(audio.currentStory?.slug == "b-1")
  }

  @Test func triggerWhilePlayingArmsStemSinglePressPlayAndDoublePressQueue() {
    let (coordinator, audio, _, _, remote, queue) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(audio.isPlaying)
    #expect(!remote.isArmed)

    // Trigger site B while A is playing
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt?.siteSlug == "b")
    #expect(remote.isArmed)

    // Simulating double stem press should add site B to queue and resume A
    remote.simulateDoubleStemPress()
    #expect(coordinator.state == .playing)
    #expect(queue.items.contains(where: { $0.storySlug == "b-1" }))
    #expect(audio.currentStory?.slug == "a-1")
    #expect(!remote.isArmed)
  }

  @Test func triggerWhilePlayingSingleStemPressPlaysNewStory() {
    let (coordinator, audio, _, _, remote, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(audio.isPlaying)

    // Trigger site B while A is playing
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    #expect(coordinator.state == .prompting)
    #expect(remote.isArmed)

    // Simulating single stem press should play site B
    remote.simulateStemPress()
    #expect(coordinator.state == .playing)
    #expect(audio.currentStory?.slug == "b-1")
    #expect(!remote.isArmed)
  }

  @Test func pauseAndResumeDuringPromptKeepsOriginalStory() async {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let queue = MockStoryQueue()
    let settings = SettingsStore()
    settings.appLanguage = .english
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      storyQueue: queue,
      settings: settings,
      dismissCountdown: .milliseconds(1)
    )

    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(audio.isPlaying)

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    #expect(coordinator.state == .prompting)
    #expect(remote.isArmed)

    // Pause audio while prompt is active
    audio.pause()
    #expect(!audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")

    // Resume audio while prompt is active
    audio.resume()
    #expect(audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")

    // Allow prompt to time out
    await coordinator.timeoutTask?.value

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")
  }

  @Test func triggerWhilePlayingDismissPreservesPausedStoryState() {
    let (coordinator, audio, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    let promptID = coordinator.pendingPrompt!.id

    audio.pause()
    #expect(!audio.isPlaying)

    coordinator.dismiss(promptID: promptID)

    #expect(coordinator.state == .playing)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(!audio.isPlaying)
  }

  // MARK: - Return to idle

  @Test func playbackFinishingReturnsToIdleAndCanPromptAgain() {
    let (coordinator, _, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(coordinator.state == .playing)

    coordinator.playbackDidFinish()
    #expect(coordinator.state == .idle)

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    #expect(coordinator.state == .prompting)
  }

  @Test func audioFinishingIsWiredBackToTheCoordinator() {
    let (coordinator, audio, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(coordinator.state == .playing)

    audio.simulatePlaybackFinished()

    #expect(coordinator.state == .idle)
  }
}
