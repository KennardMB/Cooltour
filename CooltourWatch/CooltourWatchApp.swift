import SwiftUI

@main
struct CooltourWatchApp: App {
  @State private var session = WatchSessionClient()
  @State private var wayfinding = WatchWayfinding()

  var body: some Scene {
    WindowGroup {
      WatchNowView(session: session, wayfinding: wayfinding)
        .onAppear {
          session.onApproachHaptic = { WatchHaptics.playApproach() }
          session.onPlayStartHaptic = { WatchHaptics.playPlayStart() }
          session.activate()
        }
    }
  }
}
