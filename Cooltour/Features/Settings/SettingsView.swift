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

        Section {
          Picker("App language", selection: $settings.appLanguage) {
            ForEach(AppLanguagePreference.allCases) { preference in
              Text(preference.displayName).tag(preference)
            }
          }
          Picker("Story audio", selection: $settings.audioLanguage) {
            ForEach(AudioLanguagePreference.allCases) { preference in
              Text(preference.displayName).tag(preference)
            }
          }
        } header: {
          Text("Language")
        } footer: {
          VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "language.app.footer"))
            if settings.audioLanguage == .indonesian {
              Text(String(localized: "language.audio.indonesian_footer"))
            }
          }
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
            value: env.notifications.isAuthorized
              ? String(localized: "Allowed")
              : String(localized: "Not allowed")
          )
          if !env.notifications.isAuthorized {
            Button("Request Permission") {
              Task {
                _ = await env.notifications.requestAuthorization()
              }
            }
          }
          Button("Open System Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
              UIApplication.shared.open(url)
            }
          }
        }

        Section("Content") {
          LabeledContent("Downloaded status", value: String(localized: "Offline ready"))
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
      .task {
        await env.notifications.refreshAuthorization()
      }
    }
  }

  /// Says what walking mode will actually do, including when it can't — "Always" is a big ask and
  /// the honest answer to a refusal is that the app still works, just not with the screen off.
  /// Turning walking mode off stops all use of location, but iOS still shows the granted level in
  /// Settings until the user changes it there; it can't be revoked from code.
  private var walkingModeFooter: String {
    guard env.settings.walkingMode else {
      return String(
        format: String(localized: "walking_mode.footer.off"),
        AppConfig.appName
      )
    }
    return switch env.proximity.authorizationStatus {
    case .authorizedAlways:
      String(localized: "walking_mode.footer.always")
    case .authorizedWhenInUse:
      String(localized: "walking_mode.footer.when_in_use")
    case .denied, .restricted:
      String(
        format: String(localized: "walking_mode.footer.denied"),
        AppConfig.appName
      )
    default:
      String(localized: "walking_mode.footer.default")
    }
  }
}

#Preview {
  SettingsView().environment(AppEnvironment())
}
