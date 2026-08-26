import SwiftUI

@main
struct WalkabyWatchApp: App {
  @State private var session: WatchSessionClient
  @State private var wayfinding = WatchWayfinding()
  @Environment(\.scenePhase) private var scenePhase

  init() {
    // Activate WatchConnectivity at process start so `didReceiveApplicationContext` can wake
    // the extension when the phone posts a prompt — not only after the user opens the glance.
    let client = WatchSessionClient()
    client.activate()
    _session = State(initialValue: client)
  }

  var body: some Scene {
    WindowGroup {
      WatchNowView(session: session, wayfinding: wayfinding)
        .onAppear {
          session.onApproachHaptic = { WatchHaptics.playApproach() }
          session.onPlayStartHaptic = { WatchHaptics.playPlayStart() }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
          session.isAppInForeground = (phase == .active)
        }
    }
  }
}
