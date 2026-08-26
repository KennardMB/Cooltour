import SwiftUI

struct RootView: View {
  @Environment(AppEnvironment.self) private var environment
  @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding: Bool = false

  @State private var isShowingSplash: Bool = true
  @State private var splashTask: Task<Void, Never>?

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      if !hasCompletedOnboarding {
        OnboardingFlowView()
          .transition(.opacity)
      } else {
        NowView()

        // Global Floating Simulate Site Approach Button (Only visible during active exploration)
        if environment.settings.walkingMode {
          FloatingSimulateButton(bottomPadding: 24)
        }
      }

      // Animated Splash Screen Overlay (Cold Launch only)
      if isShowingSplash {
        SplashScreenView()
          .transition(.opacity)
          .zIndex(999)
      }
    }
    // Walking mode, not the app appearing, is what starts listening now (Slice 11).
    .onAppear {
      triggerSplash()
      if environment.settings.walkingMode {
        environment.proximity.start()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
      environment.history.stopWalk()
      environment.settings.walkingMode = false
      UserDefaults.standard.set(false, forKey: AppConfig.walkingModeKey)
      environment.proximity.stop()
      environment.audio.stop()
    }
    .onChange(of: environment.settings.walkingMode) { _, isOn in
      if isOn {
        environment.proximity.start()
      } else {
        environment.proximity.stop()
        // Walk list is walk-scoped — turning walking mode off drops anything she saved for later.
        environment.playlist.clear()
        // Cancel open consent + wayfinding so Watch / Now don't keep a dead prompt (Slice 18).
        environment.narration.cancelSession()
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
