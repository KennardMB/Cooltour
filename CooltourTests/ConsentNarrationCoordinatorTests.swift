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
    timeout: Duration = .seconds(60)
  ) -> (ConsentNarrationCoordinator, MockAudioPlayerService, MockPromptVoice, MockConsentRemoteControl) {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      consentTimeout: timeout
    )
    return (coordinator, audio, voice, remote)
  }

  // MARK: - Prompting

  @Test func triggerPromptsSpeaksAndArmsTheStem() {
    let (coordinator, audio, voice, remote) = makeCoordinator()

    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt?.siteSlug == "pura-maospahit")
    #expect(voice.lastSpoken == "You're approaching Pura Maospahit. Press play to hear it.")
    #expect(remote.isArmed)
    #expect(remote.armedTitle == "The Split Gate")
    #expect(!audio.isPlaying)
  }

  // MARK: - Accept

  @Test func acceptPlaysTheStoryAndHandsBackTheStem() {
    let (coordinator, audio, voice, remote) = makeCoordinator()
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
    let (coordinator, audio, _, remote) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    remote.simulateStemPress()

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
  }

  // MARK: - Dismiss

  @Test func dismissPlaysNothing() {
    let (coordinator, audio, _, remote) = makeCoordinator()
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
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: MockPromptVoice(),
      remoteControl: MockConsentRemoteControl(),
      consentTimeout: .milliseconds(1)
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
    let (coordinator, _, _, _) = makeCoordinator()
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
    let (coordinator, audio, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let staleID = coordinator.pendingPrompt!.id
    coordinator.dismiss(promptID: staleID)

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    coordinator.accept(promptID: staleID)

    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt?.siteSlug == "b")
    #expect(audio.currentStory == nil)
  }

  // MARK: - Busy

  @Test func triggerArrivingWhileBusyIsIgnored() {
    let (coordinator, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let firstID = coordinator.pendingPrompt!.id

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))

    #expect(coordinator.pendingPrompt?.id == firstID)
    #expect(coordinator.pendingPrompt?.siteSlug == "a")
  }

  // MARK: - Return to idle

  @Test func playbackFinishingReturnsToIdleAndCanPromptAgain() {
    let (coordinator, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(coordinator.state == .playing)

    coordinator.playbackDidFinish()
    #expect(coordinator.state == .idle)

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    #expect(coordinator.state == .prompting)
  }

  @Test func audioFinishingIsWiredBackToTheCoordinator() {
    let (coordinator, audio, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(coordinator.state == .playing)

    // Drive the real seam: the player reports its story ended, which the coordinator wired in init.
    audio.simulatePlaybackFinished()

    #expect(coordinator.state == .idle)
  }
}
