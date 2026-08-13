import SwiftData
import SwiftUI

@main
struct CooltourApp: App {
  @State private var environment: AppEnvironment
  private let container: ModelContainer

  init() {
    let container: ModelContainer
    do {
      let isPreview =
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
      let config = ModelConfiguration(isStoredInMemoryOnly: isPreview)
      container = try ModelContainer(
        for: Site.self,
        Story.self,
        configurations: config
      )
    } catch {
      fatalError("Could not create the SwiftData container: \(error)")
    }

    let store = LocalContentStore(container: container)
    do {
      try store.seedIfNeeded()
    } catch {
      assertionFailure("Content pack failed to seed: \(error)")
    }

    self.container = container
    let environment = AppEnvironment(
      content: store,
      audio: AVAudioPlayerService(),
      proximity: CoreLocationProximityEngine(content: store)
    )

    // Core Location can relaunch the app straight into the background, where no view ever
    // appears — so listening has to start with the process, not with a screen. Gated on the
    // setting so an app the user hasn't opted in for stays foreground-only and silent.
    if UserDefaults.standard.bool(forKey: AppConfig.backgroundTriggeringKey) {
      environment.proximity.start()
    }

    _environment = State(initialValue: environment)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(environment)
    }
    .modelContainer(container)
  }
}
