import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
  let content: any ContentStore
  let audio: any AudioPlayerService
  let proximity: any ProximityEngine
  let narration: any NarrationCoordinator
  let storyQueue: any StoryQueue
  let notifications: any NotificationService
  let settings: SettingsStore
  let history: HistoryStore

  init(
    content: any ContentStore = LocalContentStore.inMemory(),
    audio: any AudioPlayerService = MockAudioPlayerService(),
    proximity: any ProximityEngine = MockProximityEngine(),
    narration: any NarrationCoordinator = MockNarrationCoordinator(),
    storyQueue: any StoryQueue = MockStoryQueue(),
    notifications: any NotificationService = MockNotificationService(),
    settings: SettingsStore = SettingsStore(),
    history: HistoryStore = HistoryStore.inMemory()
  ) {
    self.content = content
    self.audio = audio
    self.proximity = proximity
    self.narration = narration
    self.storyQueue = storyQueue
    self.notifications = notifications
    self.settings = settings
    self.history = history

    // Apply the persisted speed before anything can play.
    self.audio.setRate(Float(settings.defaultPlaybackSpeed))
    
    // Wire history logging. Capturing `history` weakly isn't strictly necessary since it doesn't
    // retain the proximity engine, but keeps closures clean.
    // Logged as `.pending` at trigger time; the coordinator's `onOutcome` resolves it once the
    // user answers (or the prompt times out).
    self.proximity.onEventLogged = { [weak history] event in
      history?.addEvent(from: event, outcome: .pending)
    }

    // The one place proximity meets the consent gate. Captures the local rather than self, so
    // the engine's callback can't retain the environment.
    self.proximity.onTrigger = { site, story in
      narration.handleTrigger(site: site, story: story)
    }

    // Production injects `ConsentNarrationCoordinator`; previews keep the mock, which has no
    // outcome callback to wire.
    if let consent = narration as? ConsentNarrationCoordinator {
      consent.onOutcome = { [weak history] prompt, outcome in
        history?.resolveOutcome(storySlug: prompt.storySlug, outcome: outcome)
      }
    }
  }
}
