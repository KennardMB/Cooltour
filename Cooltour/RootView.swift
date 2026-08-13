import SwiftUI

struct RootView: View {
  @Environment(AppEnvironment.self) private var environment

  var body: some View {
    TabView {
      NowView()
        .tabItem { Label("Now", systemImage: "waveform") }
      MapView()
        .tabItem { Label("Map", systemImage: "map") }
      HistoryView()
        .tabItem { Label("History", systemImage: "clock") }
      SettingsView()
        .tabItem { Label("Settings", systemImage: "gearshape") }
    }
    .onAppear {
      environment.proximity.start()
    }
  }
}

#Preview {
  RootView().environment(AppEnvironment())
}
