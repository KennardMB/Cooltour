import SwiftData
import SwiftUI

@main
struct CooltourApp: App {
    @State private var environment: AppEnvironment
    private let container: ModelContainer

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: Site.self, Story.self)
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
        _environment = State(initialValue: AppEnvironment(content: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
        }
        .modelContainer(container)
    }
}
