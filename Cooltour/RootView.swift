import SwiftUI

struct RootView: View {
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
    }
}

#Preview {
    RootView().environment(AppEnvironment())
}
