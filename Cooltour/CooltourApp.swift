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
    let storyQueue = WalkStoryQueue()
    let notifications = UNNotificationService(settings: settings)
    let narration = ConsentNarrationCoordinator(
      audio: audio,
      promptVoice: SystemPromptVoice(),
      remoteControl: SystemConsentRemoteControl(),
      storyQueue: storyQueue,
      notifications: notifications,
      settings: settings
    )
    let environment = AppEnvironment(
      content: store,
      audio: audio,
      proximity: CoreLocationProximityEngine(content: store),
      narration: narration,
      storyQueue: storyQueue,
      notifications: notifications,
      settings: settings,
      history: HistoryStore(container: container)
    )

    // Core Location can relaunch the app straight into the background, where no view ever
    // appears — so listening has to start with the process, not with a screen. Gated on the
    // setting so an app the user hasn't opted in for stays foreground-only and silent.
    if UserDefaults.standard.bool(forKey: AppConfig.walkingModeKey) {
      environment.proximity.start()
      environment.history.startWalk()
    }

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
