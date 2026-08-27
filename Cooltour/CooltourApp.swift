import SwiftData
import SwiftUI

@main
struct CooltourApp: App {
  @State private var environment: AppEnvironment
  private let container: ModelContainer

  init() {
    let isPreview =
      ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    let container = Self.makeContainer(inMemory: isPreview)

    let store = LocalContentStore(container: container)
    do {
      try store.seedIfNeeded()
    } catch {
      assertionFailure("Content pack failed to seed: \(error)")
    }

    self.container = container
    let settings = SettingsStore()
    let audio = AVAudioPlayerService(settings: settings)
    let playlist = WalkSitePlaylistService()
    let notifications = UNNotificationService(settings: settings)
    let narration = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: SystemPromptVoice(),
      approachChime: BundleApproachChimePlayer(),
      remoteControl: SystemConsentRemoteControl(),
      playlist: playlist,
      notifications: notifications,
      settings: settings
    )
    let proximity = CoreLocationProximityEngine(content: store)
    let watchSession = WCWatchSessionBridge(
      settings: settings,
      narration: narration,
      audio: audio,
      proximity: proximity
    )
    let environment = AppEnvironment(
      content: store,
      audio: audio,
      proximity: proximity,
      narration: narration,
      playlist: playlist,
      notifications: notifications,
      settings: settings,
      history: HistoryStore(container: container),
      watchSession: watchSession
    )
    watchSession.activate()

    // Tour automatically ends when app is killed; cold launch starts with walking mode off
    // until the user explicitly taps "Start Exploration". Clean up any empty walks from prior sessions.
    UserDefaults.standard.set(false, forKey: AppConfig.walkingModeKey)
    environment.settings.walkingMode = false
    environment.history.cleanupEmptyWalks()

    _environment = State(initialValue: environment)
  }

  /// Opens the on-disk store, or — if a schema change can't migrate (MVP has no VersionedSchema) —
  /// deletes it and starts fresh. Losing local history/walks is acceptable; crashing on launch is not.
  private static func makeContainer(inMemory: Bool) -> ModelContainer {
    let schema = Schema([Site.self, Story.self, Walk.self, TriggerEvent.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)

    do {
      return try ModelContainer(for: schema, configurations: [config])
    } catch {
      guard !inMemory else {
        fatalError("Could not create the SwiftData container: \(error)")
      }
      // Schema drift from Slice 11 (`wasAutoPlayed` → `outcome`) and similar MVP changes.
      let storeURL = config.url
      try? FileManager.default.removeItem(at: storeURL)
      try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
      try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))
      do {
        return try ModelContainer(for: schema, configurations: [config])
      } catch {
        fatalError("Could not recreate the SwiftData container after wipe: \(error)")
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(environment)
    }
    .modelContainer(container)
  }
}
