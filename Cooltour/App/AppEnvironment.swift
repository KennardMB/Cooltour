import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
  let content: any ContentStore
  let audio: any AudioPlayerService
  let proximity: any ProximityEngine
  let notifications: any NotificationService
  let settings: SettingsStore

  init(
    content: any ContentStore = LocalContentStore.inMemory(),
    audio: any AudioPlayerService = MockAudioPlayerService(),
    proximity: any ProximityEngine = MockProximityEngine(),
    notifications: any NotificationService = MockNotificationService(),
    settings: SettingsStore = SettingsStore()
  ) {
    self.content = content
    self.audio = audio
    self.proximity = proximity
    self.notifications = notifications
    self.settings = settings

    // Apply the persisted speed before anything can play.
    self.audio.setRate(Float(settings.defaultPlaybackSpeed))

    // The one place proximity meets playback. Auto-play is a persisted preference
    // now, not a static flag. Captures the locals rather than self, so the engine's
    // callback can't retain the environment.
    self.proximity.onTrigger = { _, story in
      guard settings.autoPlay else { return }
      audio.play(story: story)
    }
  }
}
