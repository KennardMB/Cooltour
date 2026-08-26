import Foundation
import Testing

@testable import Cooltour

@MainActor
struct NotificationServiceTests {

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
    countdown: Duration = .seconds(60)
  ) -> (
    ConsentNarrationCoordinator,
    MockAudioPlayerService,
    MockPromptVoice,
    MockConsentRemoteControl,
    MockNotificationService
  ) {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let notifications = MockNotificationService()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      notifications: notifications,
      dismissCountdown: countdown
    )
    return (coordinator, audio, voice, remote, notifications)
  }

  // MARK: - Tests

  @Test func triggerPostsLocalNotification() {
    let (coordinator, _, _, _, notifications) = makeCoordinator()

    coordinator.handleTrigger(site: makeSite(), story: makeStory())

    #expect(notifications.postedPrompts.count == 1)
    let posted = notifications.postedPrompts.first
    #expect(posted?.siteSlug == "pura-maospahit")
    #expect(posted?.storyTitle == "The Split Gate")
    #expect(notifications.withdrawnPromptIDs.isEmpty)
  }

  @Test func acceptWithdrawsNotification() {
    let (coordinator, _, _, _, notifications) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = coordinator.pendingPrompt!.id

    coordinator.accept(promptID: promptID)

    #expect(notifications.withdrawnPromptIDs == [promptID])
    #expect(notifications.postedPrompts.isEmpty)
  }

  @Test func dismissWithdrawsNotification() {
    let (coordinator, _, _, _, notifications) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = coordinator.pendingPrompt!.id

    coordinator.dismiss(promptID: promptID)

    #expect(notifications.withdrawnPromptIDs == [promptID])
    #expect(notifications.postedPrompts.isEmpty)
  }

  @Test func timeoutWithdrawsNotification() async {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let notifications = MockNotificationService()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      notifications: notifications,
      dismissCountdown: .milliseconds(1)
    )

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = notifications.postedPrompts.first!.id
    await coordinator.timeoutTask?.value

    #expect(coordinator.state == .idle)
    #expect(notifications.withdrawnPromptIDs == [promptID])
  }

  @Test func stemPressWithdrawsNotification() {
    let (coordinator, audio, _, remote, notifications) = makeCoordinator()
    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = coordinator.pendingPrompt!.id

    remote.simulateStemPress()

    #expect(coordinator.state == .playing)
    #expect(audio.isPlaying)
    #expect(notifications.withdrawnPromptIDs == [promptID])
  }

  @Test func notificationAcceptViaAppEnvironmentPlaysStory() {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let notifications = MockNotificationService()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      notifications: notifications
    )
    let env = AppEnvironment(
      audio: audio,
      narration: coordinator,
      notifications: notifications
    )

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = coordinator.pendingPrompt!.id

    notifications.simulateAnswer(.accept(promptID: promptID))

    #expect(coordinator.state == .playing)
    #expect(env.audio.isPlaying)
    #expect(env.audio.currentStory?.slug == "pura-maospahit-01")
    #expect(notifications.withdrawnPromptIDs == [promptID])
  }

  @Test func notificationDismissViaAppEnvironmentStaysSilent() {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let notifications = MockNotificationService()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      notifications: notifications
    )
    let env = AppEnvironment(
      audio: audio,
      narration: coordinator,
      notifications: notifications
    )

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = coordinator.pendingPrompt!.id

    notifications.simulateAnswer(.dismiss(promptID: promptID))

    #expect(coordinator.state == .idle)
    #expect(!env.audio.isPlaying)
    #expect(env.audio.currentStory == nil)
    #expect(notifications.withdrawnPromptIDs == [promptID])
  }

  @Test func notificationQueueViaAppEnvironmentEnqueuesStory() {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let playlist = MockWalkSitePlaylist()
    let notifications = MockNotificationService()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      playlist: playlist,
      notifications: notifications
    )
    let env = AppEnvironment(
      audio: audio,
      narration: coordinator,
      playlist: playlist,
      notifications: notifications
    )

    // Start playing story A
    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let firstPromptID = coordinator.pendingPrompt!.id
    coordinator.accept(promptID: firstPromptID)
    #expect(env.audio.isPlaying)

    // Now trigger story B and queue it via notification
    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    let promptID = coordinator.pendingPrompt!.id

    notifications.simulateAnswer(.queue(promptID: promptID))

    #expect(coordinator.state == .playing)
    #expect(env.audio.currentStory?.slug == "a-1")
    #expect(env.playlist.queuedItems.map(\.storySlug) == ["b-1"])
    #expect(notifications.withdrawnPromptIDs == [firstPromptID, promptID])
  }

  @Test func staleNotificationAnswerCannotResolveNewPrompt() {
    let audio = MockAudioPlayerService()
    let voice = MockPromptVoice()
    let remote = MockConsentRemoteControl()
    let notifications = MockNotificationService()
    let coordinator = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: voice,
      remoteControl: remote,
      notifications: notifications
    )
    let env = AppEnvironment(
      audio: audio,
      narration: coordinator,
      notifications: notifications
    )

    coordinator.handleTrigger(site: makeSite(slug: "a", name: "A"), story: makeStory(slug: "a-1"))
    let stalePromptID = coordinator.pendingPrompt!.id
    coordinator.dismiss(promptID: stalePromptID)

    coordinator.handleTrigger(site: makeSite(slug: "b", name: "B"), story: makeStory(slug: "b-1"))
    let newPromptID = coordinator.pendingPrompt!.id

    notifications.simulateAnswer(.accept(promptID: stalePromptID))

    #expect(coordinator.state == .prompting)
    #expect(coordinator.pendingPrompt?.id == newPromptID)
    #expect(env.audio.currentStory == nil)
  }

  @Test func answeringTwiceViaNotificationResolvesOnlyOnce() {
    let (coordinator, _, _, _, notifications) = makeCoordinator()
    var outcomes: [PromptOutcome] = []
    coordinator.onOutcome = { _, outcome in outcomes.append(outcome) }

    coordinator.handleTrigger(site: makeSite(), story: makeStory())
    let promptID = coordinator.pendingPrompt!.id

    coordinator.accept(promptID: promptID)
    coordinator.accept(promptID: promptID)
    coordinator.dismiss(promptID: promptID)

    #expect(coordinator.state == .playing)
    #expect(outcomes == [.played])
    #expect(notifications.withdrawnPromptIDs == [promptID])
  }
}
