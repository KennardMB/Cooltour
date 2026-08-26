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
    chime: MockApproachChimePlayer = MockApproachChimePlayer(),
    playlist: any WalkSitePlaylist = MockWalkSitePlaylist()
  ) -> (
    ConsentNarrationCoordinator, MockAudioPlayerService, MockPromptVoice,
    MockApproachChimePlayer, MockConsentRemoteControl,
    any WalkSitePlaylist
  ) {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let settings = SettingsStore()
    settings.appLanguage = .english
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      approachChime: chime,
      remoteControl: remote,
      playlist: playlist,
      settings: settings,
      dismissCountdown: countdown
    )
    return (coordinator, audio, voice, chime, remote, playlist)
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
    let settings = SettingsStore()
    settings.appLanguage = .indonesian
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      playlist: MockWalkSitePlaylist(),
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
    let (coordinator, audio, _, _, remote, playlist) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let id = coordinator.pendingPrompt!.id

    coordinator.dismiss(promptID: id)

    #expect(coordinator.state == .idle)
    #expect(audio.currentStory == nil)
    #expect(!remote.isArmed)
    #expect(playlist.carouselEntries.isEmpty)
  }

  // MARK: - Timeout

  @Test func noAnswerTimesOutIntoSilence() async {
    var outcomes: [PromptOutcome] = []
    let audio = MockAudioPlayerService()
    let settings = SettingsStore()
    settings.appLanguage = .english
    let playlist = MockWalkSitePlaylist()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: MockPromptVoice(),
      remoteControl: MockConsentRemoteControl(),
      playlist: playlist,
      settings: settings,
      dismissCountdown: .milliseconds(1)
    )
    coordinator.onOutcome = { _, outcome in outcomes.append(outcome) }

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    await coordinator.timeoutTask?.value

    #expect(coordinator.state == .idle)
    #expect(audio.currentStory == nil)
    #expect(playlist.carouselEntries.isEmpty)
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
    let (coordinator, _, _, _, _, playlist) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let firstID = coordinator.pendingPrompt!.id

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))

    #expect(coordinator.pendingPrompt?.id == firstID)
    #expect(playlist.queuedItems.map(\.storySlug) == ["b-1"])
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

  @Test func queueWhileIdleStartsThatStory() {
    let (coordinator, audio, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    #expect(coordinator.state == .prompting)
    #expect(audio.currentStory == nil)

    coordinator.queue(promptID: coordinator.pendingPrompt!.id)

    #expect(coordinator.state == .playing)
    #expect(audio.currentStory?.slug == "a-1")
  }

  @Test func queueKeepsUnderlyingStoryPlaying() {
    let (coordinator, audio, _, _, _, playlist) = makeCoordinator()
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
    #expect(playlist.queuedItems.map(\.storySlug) == ["b-1"])
    #expect(outcomes.last == .queued)
  }

  @Test func dismissKeepsUnderlyingStoryPlaying() {
    let (coordinator, audio, _, _, _, playlist) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))

    coordinator.dismiss(promptID: coordinator.pendingPrompt!.id)

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(playlist.queuedItems.isEmpty)
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
    let (coordinator, audio, _, _, remote, playlist) = makeCoordinator()
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
    #expect(playlist.queuedItems.contains(where: { $0.storySlug == "b-1" }))
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
    let settings = SettingsStore()
    settings.appLanguage = .english
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      playlist: MockWalkSitePlaylist(),
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

  // MARK: - Watch session / wayfinding (Slices 18 + 20)

  @Test func cancelSessionClearsPromptAndWayfinding() {
    let (coordinator, audio, _, _, remote, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    #expect(coordinator.state == .prompting)

    coordinator.cancelSession()

    #expect(coordinator.state == .idle)
    #expect(coordinator.pendingPrompt == nil)
    #expect(coordinator.wayfindingTarget == nil)
    #expect(!remote.isArmed)
    #expect(!audio.isPlaying)
  }

  @Test func acceptArmsWayfindingQueueDoesNot() {
    let (coordinator, _, _, _, _, playlist) = makeCoordinator()
    let siteA = makeSite(slug: "a", name: "A")
    let storyA = makeStory(slug: "a-1", title: "A1")
    coordinator.handleTrigger(site: siteA, story: storyA)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)

    #expect(coordinator.wayfindingTarget?.siteSlug == "a")
    #expect(coordinator.wayfindingTarget?.latitude == siteA.latitude)

    let siteB = makeSite(slug: "b", name: "B")
    let storyB = makeStory(slug: "b-1", title: "B1")
    coordinator.handleTrigger(site: siteB, story: storyB)
    coordinator.queue(promptID: coordinator.pendingPrompt!.id)

    #expect(playlist.queuedItems.count == 1)
    #expect(coordinator.wayfindingTarget?.siteSlug == "a")
  }

  @Test func playNowAppendsAfterQueuedSites() {
    let playlist = MockWalkSitePlaylist()
    let (coordinator, audio, _, _, _, _) = makeCoordinator(playlist: playlist)
    let siteA = makeSite(slug: "a", name: "A")
    let storyA = makeStory(slug: "a-1", title: "A1")
    let siteB = makeSite(slug: "b", name: "B")
    let storyB = makeStory(slug: "b-1", title: "B1")
    let siteC = makeSite(slug: "c", name: "C")
    let storyC = makeStory(slug: "c-1", title: "C1")
    let siteD = makeSite(slug: "d", name: "D")
    let storyD = makeStory(slug: "d-1", title: "D1")

    // [a, b▶, cq] + play-now d → [a, b, cq, d▶]
    coordinator.handleTrigger(site: siteA, story: storyA)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: siteB, story: storyB)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: siteC, story: storyC)
    coordinator.queue(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: siteD, story: storyD)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)

    #expect(audio.currentStory?.slug == "d-1")
    #expect(playlist.carouselEntries.map(\.storySlug) == ["a-1", "b-1", "c-1", "d-1"])
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true, true, false, true])
    #expect(playlist.playheadIndex == 3)
    #expect(playlist.queuedItems.map(\.storySlug) == ["c-1"])
  }

  @Test func finishAdvancesParkedNeighborBeforeLaterQueue() {
    let playlist = MockWalkSitePlaylist()
    let (coordinator, audio, _, _, _, _) = makeCoordinator(playlist: playlist)
    let siteA = makeSite(slug: "a", name: "A")
    let storyA = makeStory(slug: "a-1", title: "A1")
    let siteB = makeSite(slug: "b", name: "B")
    let storyB = makeStory(slug: "b-1", title: "B1")
    let siteC = makeSite(slug: "c", name: "C")
    let storyC = makeStory(slug: "c-1", title: "C1")

    // [a, b▶] then queue c → [a, b▶, cq]; swipe back to a and finish → b, not c
    coordinator.handleTrigger(site: siteA, story: storyA)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: siteB, story: storyB)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    coordinator.handleTrigger(site: siteC, story: storyC)
    coordinator.queue(promptID: coordinator.pendingPrompt!.id)
    #expect(playlist.carouselEntries.map(\.storySlug) == ["a-1", "b-1", "c-1"])
    #expect(playlist.playheadIndex == 1)

    _ = playlist.select(index: 0)
    #expect(playlist.playheadIndex == 0)

    audio.simulatePlaybackFinished()

    #expect(coordinator.state == .playing)
    #expect(audio.currentStory?.slug == "b-1")
  }

  @Test func finishingReplacesWayfindingWithQueuedSiteInOneStep() {
    let (coordinator, audio, _, _, _, _) = makeCoordinator()
    let siteA = makeSite(slug: "a", name: "A")
    let storyA = makeStory(slug: "a-1", title: "A1")
    let siteB = makeSite(slug: "b", name: "B")
    let storyB = makeStory(slug: "b-1", title: "B1")

    coordinator.handleTrigger(site: siteA, story: storyA)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(coordinator.wayfindingTarget?.siteSlug == "a")

    coordinator.handleTrigger(site: siteB, story: storyB)
    coordinator.queue(promptID: coordinator.pendingPrompt!.id)

    coordinator.playbackDidFinish()

    #expect(coordinator.state == .playing)
    #expect(coordinator.wayfindingTarget?.siteSlug == "b")
    #expect(audio.currentStory?.slug == "b-1")
  }

  @Test func playbackEndWithEmptyQueueClearsWayfinding() {
    let (coordinator, _, _, _, _, _) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    #expect(coordinator.wayfindingTarget != nil)

    coordinator.playbackDidFinish()

    #expect(coordinator.state == .idle)
    #expect(coordinator.wayfindingTarget == nil)
  }

  @Test func selectPlaylistIndexStartsStoryFromZeroAndArmsWayfinding() {
    let playlist = MockWalkSitePlaylist()
    let (coordinator, audio, _, _, _, _) = makeCoordinator(playlist: playlist)
    let siteA = makeSite(slug: "a", name: "A")
    let storyA = makeStory(slug: "a-1", title: "A1")
    let siteB = makeSite(slug: "b", name: "B")
    let storyB = makeStory(slug: "b-1", title: "B1")

    coordinator.handleTrigger(site: siteA, story: storyA)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    audio.seek(toProgress: 0.5)
    #expect(coordinator.wayfindingTarget?.siteSlug == "a")

    coordinator.handleTrigger(site: siteB, story: storyB)
    coordinator.queue(promptID: coordinator.pendingPrompt!.id)

    coordinator.selectPlaylistIndex(1)

    #expect(playlist.playheadIndex == 1)
    #expect(playlist.carouselEntries.map(\.siteSlug) == ["a", "b"])
    #expect(audio.currentStory?.slug == "b-1")
    #expect(audio.progress == 0)
    #expect(audio.isPlaying)
    #expect(coordinator.state == .playing)
    #expect(coordinator.wayfindingTarget?.siteSlug == "b")

    coordinator.selectPlaylistIndex(0)

    #expect(playlist.playheadIndex == 0)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(audio.progress == 0)
    #expect(coordinator.wayfindingTarget?.siteSlug == "a")
  }

  @Test func selectPlaylistIndexOutOfRangeIsNoOp() {
    let playlist = MockWalkSitePlaylist()
    let (coordinator, audio, _, _, _, _) = makeCoordinator(playlist: playlist)
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1", title: "A1"))
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    audio.seek(toProgress: 0.4)

    coordinator.selectPlaylistIndex(9)

    #expect(playlist.playheadIndex == 0)
    #expect(audio.currentStory?.slug == "a-1")
    #expect(audio.progress == 0.4)
    #expect(coordinator.wayfindingTarget?.siteSlug == "a")
  }

  @Test func selectPlaylistIndexWhilePromptingIsNoOp() {
    let playlist = MockWalkSitePlaylist()
    let (coordinator, audio, _, _, _, _) = makeCoordinator(playlist: playlist)
    let siteA = makeSite(slug: "a", name: "A")
    let storyA = makeStory(slug: "a-1", title: "A1")
    let siteB = makeSite(slug: "b", name: "B")
    let storyB = makeStory(slug: "b-1", title: "B1")

    coordinator.handleTrigger(site: siteA, story: storyA)
    coordinator.accept(promptID: coordinator.pendingPrompt!.id)
    audio.seek(toProgress: 0.5)

    coordinator.handleTrigger(site: siteB, story: storyB)
    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt != nil)

    let storyBefore = audio.currentStory?.slug
    let playingBefore = audio.isPlaying
    let progressBefore = audio.progress
    let playheadBefore = playlist.playheadIndex

    coordinator.selectPlaylistIndex(0)

    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt != nil)
    #expect(audio.currentStory?.slug == storyBefore)
    #expect(audio.isPlaying == playingBefore)
    #expect(audio.progress == progressBefore)
    #expect(playlist.playheadIndex == playheadBefore)
  }
}
