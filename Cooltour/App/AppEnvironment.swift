import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
  let content: any ContentStore
  let audio: any AudioPlayerService
  let proximity: any ProximityEngine
  let notifications: any NotificationService
  let settings: SettingsStore
  let history: HistoryStore

  init(
    content: any ContentStore = LocalContentStore.inMemory(),
    audio: any AudioPlayerService = MockAudioPlayerService(),
    proximity: any ProximityEngine = MockProximityEngine(),
    notifications: any NotificationService = MockNotificationService(),
    settings: SettingsStore = SettingsStore(),
    history: HistoryStore = HistoryStore.inMemory()
  ) {
    self.content = content
    self.audio = audio
    self.proximity = proximity
    self.notifications = notifications
    self.settings = settings
    self.history = history

    // Apply the persisted speed before anything can play.
    self.audio.setRate(Float(settings.defaultPlaybackSpeed))
    
    // Wire history logging. Capturing `history` weakly isn't strictly necessary since it doesn't
    // retain the proximity engine, but keeps closures clean. We use the settings from the closure 
    // to record whether it was auto-played.
    self.proximity.onEventLogged = { [weak history, weak settings] event in
      let autoPlay = settings?.autoPlay ?? false
      history?.addEvent(from: event, wasAutoPlayed: autoPlay)
    }

    // The one place proximity meets playback. Auto-play is a persisted preference
    // now, not a static flag. Captures the locals rather than self, so the engine's
    // callback can't retain the environment.
    self.proximity.onTrigger = { _, story in
      guard settings.autoPlay else { return }
      audio.play(story: story)
    }
  }
}
