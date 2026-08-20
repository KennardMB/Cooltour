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
  let packs: any ContentPackLibrary
  let settings: SettingsStore
  let history: HistoryStore
  var packCooldown = PackPromptCooldown()

  init(
    content: any ContentStore = LocalContentStore.inMemory(),
    audio: any AudioPlayerService = MockAudioPlayerService(),
    proximity: any ProximityEngine = MockProximityEngine(),
    narration: any NarrationCoordinator = MockNarrationCoordinator(),
    storyQueue: any StoryQueue = MockStoryQueue(),
    notifications: any NotificationService = MockNotificationService(),
    packs: any ContentPackLibrary = MockContentPackLibrary(),
    settings: SettingsStore = SettingsStore(),
    history: HistoryStore = HistoryStore.inMemory()
  ) {
    self.content = content
    self.audio = audio
    self.proximity = proximity
    self.narration = narration
    self.storyQueue = storyQueue
    self.notifications = notifications
    self.packs = packs
    self.settings = settings
    self.history = history

    // Apply the persisted speed before anything can play.
    self.audio.setRate(Float(settings.defaultPlaybackSpeed))

    self.proximity.onEventLogged = { [weak history] event in
      history?.addEvent(from: event, outcome: .pending)
    }

    // Story triggers go through consent. Pack-region entry never does.
    self.proximity.onTrigger = { site, story in
      narration.handleTrigger(site: site, story: story)
    }

    self.proximity.onPackRegionEntered = { [weak self] pack in
      guard let self else { return }
      guard self.packCooldown.shouldPrompt(packID: pack.id) else { return }
      self.packCooldown.recordIgnore(packID: pack.id)
      self.notifications.postPackAvailable(pack)
    }

    self.notifications.onPackDownloadRequested = { [weak self] packID in
      self?.downloadPack(packID)
    }
    self.notifications.onPackNotNow = { [weak self] packID in
      self?.packCooldown.recordNotNow(packID: packID)
    }

    if let consent = narration as? ConsentNarrationCoordinator {
      consent.onOutcome = { [weak history] prompt, outcome in
        history?.resolveOutcome(storySlug: prompt.storySlug, outcome: outcome)
      }
    }
  }

  func syncPackGeofences() {
    let pending =
      packs.catalog?.packs.filter { pack in
        if case .installed = packs.status(for: pack.id) { return false }
        return true
      } ?? []
    proximity.setUninstalledPacks(settings.walkingMode ? pending : [])
  }

  func downloadPack(_ packID: String) {
    if audio.currentStory?.site?.packID == packID {
      audio.stop()
    }
    Task { [weak self] in
      await self?.packs.download(packID)
      self?.syncPackGeofences()
    }
  }

  func deletePack(_ packID: String) {
    if audio.currentStory?.site?.packID == packID {
      audio.stop()
    }
    Task { [weak self] in
      await self?.packs.delete(packID)
      self?.syncPackGeofences()
    }
  }
}
