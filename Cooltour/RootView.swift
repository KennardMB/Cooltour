import SwiftUI

struct RootView: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    @Bindable var env = environment
    ZStack(alignment: .bottomTrailing) {
      TabView(selection: $env.selectedTab) {
        NowView()
          .tag(AppTab.now)
          .tabItem { Label("Now", systemImage: "waveform") }
        MapView()
          .tag(AppTab.map)
          .tabItem { Label("Map", systemImage: "map") }
        NavigationStack {
          MyExplorationsView()
        }
        .tag(AppTab.exploration)
        .tabItem { Label("Exploration", systemImage: "clock") }
        NavigationStack {
          SettingsView()
        }
        .tag(AppTab.settings)
        .tabItem { Label("Settings", systemImage: "gearshape") }
      }

      // Global Floating Simulate Site Approach Button (Above TabBar)
      FloatingSimulateButton(bottomPadding: 68)
    }
    // Walking mode, not the app appearing, is what starts listening now (Slice 11). A walk that
    // was on when the app was last quit resumes on launch; otherwise the app stays silent until
    // the user turns walking mode on.
    .onAppear {
      if environment.settings.walkingMode {
        environment.proximity.start()
      }
    }
    .onChange(of: environment.settings.walkingMode) { _, isOn in
      if isOn {
        environment.proximity.start()
      } else {
        environment.proximity.stop()
        // Queue is walk-scoped — turning walking mode off drops anything she saved for later.
        environment.storyQueue.clear()
      }
    }
    .onChange(of: environment.proximity.isListening) { _, isListening in
      if isListening {
        environment.history.startWalk()
      } else {
        environment.history.stopWalk()
      }
    }
    .environment(\.locale, environment.settings.effectiveLocale)
    .onChange(of: environment.settings.appLanguage) { _, _ in
      environment.notifications.syncLocalizedContent()
    }
  }
}

#Preview {
  RootView().environment(AppEnvironment())
}
