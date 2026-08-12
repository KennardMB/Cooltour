import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        @Bindable var settings = env.settings

        NavigationStack {
            List {
                Section("Playback") {
                    Toggle("Auto-play nearby stories", isOn: $settings.autoPlay)

                    Picker("Default Speed", selection: $settings.defaultPlaybackSpeed) {
                        ForEach(SettingsStore.availablePlaybackSpeeds, id: \.self) { speed in
                            Text("\(speed.formatted())×").tag(speed)
                        }
                    }
                    .onChange(of: settings.defaultPlaybackSpeed) { _, newSpeed in
                        env.audio.setRate(Float(newSpeed))
                    }
                }

                Section("Permissions") {
                    LabeledContent("Notifications", value: env.notifications.isAuthorized ? "Allowed" : "Not requested")
                    Button("Open System Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                Section("Content") {
                    LabeledContent("Downloaded status", value: "Offline ready")
                    LabeledContent("Sites loaded", value: "\(env.content.siteCount)")
                }

                Section("About") {
                    LabeledContent("App", value: AppConfig.appName)
                }

                Section("Debug") {
                    NavigationLink("Content pack") { ContentDebugView() }
                    NavigationLink("Proximity") { ProximityDebugView() }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView().environment(AppEnvironment())
}
