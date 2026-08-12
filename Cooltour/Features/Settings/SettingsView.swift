import CoreLocation
import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    /// The engine reads this same key at `start()` — one source of truth, no second copy.
    @AppStorage(AppConfig.backgroundTriggeringKey) private var backgroundTriggering = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Background triggering", isOn: $backgroundTriggering)
                        .onChange(of: backgroundTriggering) { _, isOn in
                            // Restart so the engine picks the setting up: it decides on the
                            // background session and the monitored geofences at start().
                            let wasListening = env.proximity.isListening
                            env.proximity.stop()
                            if isOn || wasListening { env.proximity.start() }
                        }
                    LabeledContent("Location access", value: env.proximity.authorizationStatus.displayName)
                } header: {
                    Text("Background")
                } footer: {
                    Text(backgroundFooter)
                }

                Section("Permissions") {
                    LabeledContent("Notifications", value: env.notifications.isAuthorized ? "Allowed" : "Not requested")
                }
                Section("Playback") {
                    LabeledContent("Speed", value: env.audio.rate.formatted() + "×")
                    LabeledContent("Auto-play", value: AppConfig.autoPlayDefault ? "On" : "Off")
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

    /// Says what the app will actually do, including when it can't — "Always" is a big ask and
    /// the honest answer to a refusal is that the app still works, just not with the screen off.
    private var backgroundFooter: String {
        guard backgroundTriggering else {
            return "Stories only trigger while \(AppConfig.appName) is open on screen."
        }
        return switch env.proximity.authorizationStatus {
        case .authorizedAlways:
            "Stories trigger with the app in your pocket or the screen locked. Triggers are listed under Debug ▸ Proximity."
        case .authorizedWhenInUse:
            "Needs “Always” to trigger with the screen locked — grant it in iOS Settings ▸ Privacy ▸ Location Services. Until then triggering works only with the app open."
        case .denied, .restricted:
            "Location is off for \(AppConfig.appName), so nothing can trigger. Turn it on in iOS Settings."
        default:
            "Start listening to be asked for location access."
        }
    }
}

#Preview {
    SettingsView().environment(AppEnvironment())
}
