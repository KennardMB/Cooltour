import CoreLocation
import SwiftUI

struct SettingsView: View {
  @Environment(AppEnvironment.self) private var env

  var body: some View {
    @Bindable var settings = env.settings

    NavigationStack {
      List {
        Section {
          // No manual restart here: `RootView` observes `walkingMode` and starts or stops the
          // engine, which is where the background session and geofences are decided.
          Toggle("Walking mode", isOn: $settings.walkingMode)
          LabeledContent(
            "Location access",
            value: env.proximity.authorizationStatus.displayName
          )
        } header: {
          Text("Walking mode")
        } footer: {
          Text(walkingModeFooter)
        }

        Section("Playback") {
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
          LabeledContent(
            "Notifications",
            value: env.notifications.isAuthorized ? "Allowed" : "Not requested"
          )
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

  /// Says what walking mode will actually do, including when it can't — "Always" is a big ask and
  /// the honest answer to a refusal is that the app still works, just not with the screen off.
  /// Turning walking mode off stops all use of location, but iOS still shows the granted level in
  /// Settings until the user changes it there; it can't be revoked from code.
  private var walkingModeFooter: String {
    guard env.settings.walkingMode else {
      return
        "Turn on walking mode to listen for nearby stories. \(AppConfig.appName) asks before playing each one."
    }
    return switch env.proximity.authorizationStatus {
    case .authorizedAlways:
      "Listening with the app in your pocket or the screen locked. Triggers are listed under Debug ▸ Proximity."
    case .authorizedWhenInUse:
      "Needs “Always” to keep listening with the screen locked or after the app closes — grant it in iOS Settings ▸ Privacy ▸ Location Services. Until then it listens only while open."
    case .denied, .restricted:
      "Location is off for \(AppConfig.appName), so nothing can trigger. Turn it on in iOS Settings."
    default:
      "Grant location access to start listening."
    }
  }
}

#Preview {
  SettingsView().environment(AppEnvironment())
}
