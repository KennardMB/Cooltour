import SwiftUI

public enum AppTab: Int, CaseIterable, Sendable {
  case now = 0
  case map = 1
  case exploration = 2
  case settings = 3
}

@MainActor
@Observable
final class AppEnvironment {
  var selectedTab: AppTab = .now
  let content: any ContentStore
  let audio: any AudioPlayerService
  let proximity: any ProximityEngine
  let narration: any NarrationCoordinator
  let playlist: any WalkSitePlaylist
  let notifications: any NotificationService
  let settings: SettingsStore
  let history: HistoryStore
  /// Slice 17 ships the mock; Slice 18 swaps in `WCWatchSessionBridge`. Default stays mock so
  /// previews never activate WatchConnectivity.
  let watchSession: any WatchSessionBridge

  init(
    content: any ContentStore = LocalContentStore.inMemory(),
    audio: any AudioPlayerService = MockAudioPlayerService(),
    proximity: any ProximityEngine = MockProximityEngine(),
    narration: any NarrationCoordinator = MockNarrationCoordinator(),
    playlist: any WalkSitePlaylist = MockWalkSitePlaylist(),
    notifications: any NotificationService = MockNotificationService(),
    settings: SettingsStore = SettingsStore(),
    history: HistoryStore = HistoryStore.inMemory(),
    watchSession: any WatchSessionBridge = MockWatchSessionBridge()
  ) {
    self.content = content
    self.audio = audio
    self.proximity = proximity
    self.narration = narration
    self.playlist = playlist
    self.notifications = notifications
    self.settings = settings
    self.history = history
    self.watchSession = watchSession

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

    // Route interactive notification answers into the narration coordinator.
    self.notifications.onAnswer = { [weak narration] answer in
      switch answer {
      case .accept(let id):
        narration?.accept(promptID: id)
      case .dismiss(let id):
        narration?.dismiss(promptID: id)
      case .queue(let id):
        narration?.queue(promptID: id)
      }
    }

    // Production injects `ConsentNarrationCoordinator`; previews keep the mock, which has no
    // outcome callback to wire.
    if let consent = narration as? ConsentNarrationCoordinator {
      consent.onOutcome = { [weak history] prompt, outcome in
        history?.resolveOutcome(storySlug: prompt.storySlug, outcome: outcome)
      }
      consent.onWayfindingTargetChange = { [weak watchSession] _ in
        if let wc = watchSession as? WCWatchSessionBridge {
          wc.pushIfNeeded()
        } else {
          // Mock / tests: still record a push of the latest snapshot shape.
        }
      }
    }

    // Watch commands land on the same coordinator + walking-mode store as Now / notifications.
    if let mock = watchSession as? MockWatchSessionBridge {
      mock.onCommand = { [weak settings, weak narration] command in
        switch command {
        case .accept(let id):
          narration?.accept(promptID: id)
        case .queue(let id):
          narration?.queue(promptID: id)
        case .dismiss(let id):
          narration?.dismiss(promptID: id)
        case .setWalkingMode(let enabled):
          settings?.walkingMode = enabled
        }
      }
    }
  }
}
