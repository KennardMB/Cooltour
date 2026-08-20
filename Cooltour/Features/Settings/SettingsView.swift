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

        Section("Downloaded content") {
          ObservingPacks(library: env.packs) { catalog, error in
            LabeledContent("Denpasar", value: "Included with the app")
              .accessibilityHint("Ships with \(AppConfig.appName) and cannot be deleted.")

            if let error {
              Text(error)
                .foregroundStyle(.secondary)
              Button("Retry") {
                Task {
                  await env.packs.refreshCatalog()
                  env.syncPackGeofences()
                }
              }
            }

            ForEach(catalog?.packs ?? []) { pack in
              packRow(pack)
            }
          }
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

  @ViewBuilder
  private func packRow(_ pack: RemotePack) -> some View {
    let status = env.packs.status(for: pack.id)
    let sizeText = String(format: "%.1f MB", Double(pack.sizeBytes) / 1_000_000)
    VStack(alignment: .leading, spacing: 8) {
      LabeledContent(pack.name, value: sizeText)
      switch status {
      case .notInstalled:
        Button("Download") { env.downloadPack(pack.id) }
          .accessibilityHint("Downloads \(pack.name) stories to this iPhone.")
      case .downloading(let progress):
        ProgressView(value: progress)
        Button("Cancel", role: .cancel) { env.packs.cancel(pack.id) }
      case .installed(let version, _):
        Text("Installed · \(version)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Delete", role: .destructive) { env.deletePack(pack.id) }
          .accessibilityHint("Removes \(pack.name) stories from this iPhone. Denpasar stays.")
      case .failed(let message):
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Retry") { env.downloadPack(pack.id) }
      }
    }
    .accessibilityElement(children: .contain)
  }
}

/// Opens `any ContentPackLibrary` so Observation tracks catalog and status.
private struct ObservingPacks<Content: View>: View {
  let library: any ContentPackLibrary
  @ViewBuilder let content: (PackCatalog?, String?) -> Content

  var body: some View {
    observe(library)
  }

  private func observe<L: ContentPackLibrary>(_ library: L) -> Content {
    if let catalog = library.catalog {
      for pack in catalog.packs {
        _ = library.status(for: pack.id)
      }
    }
    return content(library.catalog, library.lastCatalogError)
  }
}

#Preview {
  SettingsView().environment(AppEnvironment())
}
