import CoreLocation
import SwiftUI

/// Temporary Slice 3/4 acceptance surface: shows the live fix, every site's distance and armed
/// state, and the trigger log. Delete once the Now screen (Slice 5) shows this for real.
struct ProximityDebugView: View {
  @Environment(AppEnvironment.self) private var env

  private var engine: CoreLocationProximityEngine? {
    env.proximity as? CoreLocationProximityEngine
  }

  var body: some View {
    List {
      engineSection
      fixSection
      triggerSection
      distanceSection
    }
    .navigationTitle("Proximity")
    .navigationBarTitleDisplayMode(.inline)
    // Background triggering only means anything if the engine outlives this screen.
    .onDisappear { if !env.settings.backgroundTriggering { env.proximity.stop() } }
  }

  private var engineSection: some View {
    Section("Engine") {
      Button(env.proximity.isListening ? "Stop listening" : "Start listening") {
        if env.proximity.isListening {
          env.proximity.stop()
        } else {
          env.proximity.start()
        }
      }
      LabeledContent(
        "Permission",
        value: env.proximity.authorizationStatus.displayName
      )
      LabeledContent(
        "Background",
        value: env.settings.backgroundTriggering ? "On" : "Off"
      )
      LabeledContent("Last geofence wake", value: wakeText)
      LabeledContent(
        "Auto-play",
        value: env.settings.autoPlay ? "On" : "Off"
      )
      LabeledContent("Playing", value: env.audio.currentStory?.title ?? "—")
    }
  }

  /// Distinguishes "the system never woke us" from "it woke us but no fix was good enough".
  private var wakeText: String {
    guard let wake = engine?.lastWake else {
      return env.settings.backgroundTriggering ? "None yet" : "—"
    }
    return
      "\(wake.siteSlug) · \(wake.date.formatted(date: .omitted, time: .shortened))"
  }

  @ViewBuilder
  private var fixSection: some View {
    Section("Last fix") {
      if let fix = env.proximity.lastFix {
        LabeledContent(
          "Coordinate",
          value: String(format: "%.5f, %.5f", fix.latitude, fix.longitude)
        )
        LabeledContent("Accuracy") {
          Label(
            "±\(Int(fix.horizontalAccuracyMeters)) m",
            systemImage: fix.isTrusted
              ? "checkmark.circle.fill" : "xmark.octagon.fill"
          )
          .foregroundStyle(fix.isTrusted ? .green : .red)
          .labelStyle(.titleAndIcon)
        }
        .accessibilityLabel(
          fix.isTrusted
            ? "Accuracy \(Int(fix.horizontalAccuracyMeters)) meters, trusted"
            : "Accuracy \(Int(fix.horizontalAccuracyMeters)) meters, too vague to trigger"
        )
        LabeledContent(
          "At",
          value: fix.date.formatted(date: .omitted, time: .standard)
        )
        if !fix.isTrusted {
          Text(
            "Worse than \(Int(AppConfig.maxLocationAccuracyMeters)) m — staying silent."
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      } else {
        Text(
          env.proximity.isListening ? "Waiting for a fix…" : "Not listening."
        )
        .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private var triggerSection: some View {
    Section("Triggers (\(env.history.recentEvents.count))") {
      if env.history.recentEvents.isEmpty {
        Text("No triggers yet")
          .foregroundStyle(.tertiary)
      }
      ForEach(env.history.recentEvents) { event in
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(event.storyTitle).font(.headline)
            Spacer()
            Text(event.date.formatted(date: .omitted, time: .shortened))
              .font(.caption.monospacedDigit())
              .foregroundStyle(.secondary)
          }
          Text(event.siteName).font(.subheadline)
          HStack {
            Text("Distance: \(Int(event.distanceMeters))m")
            Text("•")
            Text("GPS error: \(Int(event.horizontalAccuracyMeters))m")
          }
          .font(.caption)
          .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }

    }
  }

  private var distanceSection: some View {
    Section("Distances") {
      ForEach(env.proximity.nearbySites) { nearby in
        HStack {
          VStack(alignment: .leading) {
            Text(nearby.name)
            Text("radius \(Int(nearby.triggerRadiusMeters)) m")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
          Text("\(Int(nearby.distanceMeters)) m")
            .monospacedDigit()
            .foregroundStyle(
              nearby.isInsideRadius ? Color.green : Color.primary
            )
          Image(systemName: nearby.isArmed ? "bell.fill" : "bell.slash.fill")
            .foregroundStyle(nearby.isArmed ? Color.secondary : Color.orange)
            .accessibilityLabel(
              nearby.isArmed ? "Armed" : "Already played, waiting to re-arm"
            )
        }
      }
      if env.proximity.nearbySites.isEmpty {
        Text("Distances appear once a fix arrives.").foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  let env = AppEnvironment()
  NavigationStack {
    ProximityDebugView()
  }
  .environment(env)
  .task {
    // Fake one trigger so the canvas shows a populated screen.
    guard let engine = env.proximity as? MockProximityEngine,
      let site = env.content.allSites().first
    else { return }
    engine.nearbySites = env.content.allSites().enumerated().map {
      index,
      site in
      NearbySite(
        id: site.slug,
        name: site.name,
        triggerRadiusMeters: site.triggerRadiusMeters,
        distanceMeters: Double(index) * 120 + 12,
        isArmed: index != 0
      )
    }
    engine.lastFix = ProximityFix(
      latitude: site.latitude,
      longitude: site.longitude,
      horizontalAccuracyMeters: 9,
      date: .now,
      isTrusted: true
    )
    engine.start()
    engine.simulateTrigger(site: site, distanceMeters: 12)
  }
}
