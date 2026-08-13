import SwiftUI

struct SettingsView: View {
  @Environment(AppEnvironment.self) private var env

  var body: some View {
    NavigationStack {
      List {
        Section("Permissions") {
          LabeledContent(
            "Notifications",
            value: env.notifications.isAuthorized ? "Allowed" : "Not requested"
          )
        }
        Section("Playback") {
          LabeledContent("Speed", value: env.audio.rate.formatted() + "×")
          LabeledContent(
            "Auto-play",
            value: AppConfig.autoPlayDefault ? "On" : "Off"
          )
        }
        Section("About") {
          LabeledContent("App", value: AppConfig.appName)
        }
        Section("Debug") {
          NavigationLink("Content pack") { ContentDebugView() }
          NavigationLink("Proximity") { ProximityDebugView() }
          LabeledContent("Sites loaded", value: "\(env.content.siteCount)")
        }
      }
      .navigationTitle("Settings")
    }
  }
}

#Preview {
  SettingsView().environment(AppEnvironment())
}
