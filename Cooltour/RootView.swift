import SwiftUI

struct RootView: View {
  @Environment(AppEnvironment.self) private var environment
  @Environment(\.scenePhase) private var scenePhase

  @State private var isShowingSplash: Bool = true
  @State private var splashTask: Task<Void, Never>?

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

      // Animated Splash Screen Overlay (Launch + Foregrounding)
      if isShowingSplash {
        SplashScreenView()
          .transition(.opacity)
          .zIndex(999)
      }
    }
    // Walking mode, not the app appearing, is what starts listening now (Slice 11). A walk that
    // was on when the app was last quit resumes on launch; otherwise the app stays silent until
    // the user turns walking mode on.
    .onAppear {
      triggerSplash()
      if environment.settings.walkingMode {
        environment.proximity.start()
      }
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      // Show splash screen every time the user re-opens from background / recent apps
      if newPhase == .active && (oldPhase == .background || oldPhase == .inactive) {
        triggerSplash()
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

  private func triggerSplash() {
    splashTask?.cancel()
    isShowingSplash = true
    splashTask = Task {
      try? await Task.sleep(for: .milliseconds(1200))
      guard !Task.isCancelled else { return }
      withAnimation(.easeOut(duration: 0.35)) {
        isShowingSplash = false
      }
    }
  }
}

#Preview {
  RootView().environment(AppEnvironment())
}
