import CoreLocation
import SwiftUI

struct NowView: View {
  @Environment(AppEnvironment.self) private var env

  var body: some View {
    @Bindable var settings = env.settings

    NavigationStack {
      // Opens `any NarrationCoordinator` so Observation tracks the concrete `@Observable`
      // type. Reading `env.narration.state` on the existential alone does not refresh the view.
      ObservingNarration(coordinator: env.narration) { state, prompt in
        VStack(spacing: 24) {
          Text(statusLine(state: state, prompt: prompt))
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

          // The single control: walking mode. Toggling it is what starts and stops listening —
          // `RootView` observes the same value. Nanda's Slice 14 rebuilds this screen around it.
          Toggle("Walking mode", isOn: $settings.walkingMode)
            .toggleStyle(.button)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Listens for nearby stories and asks before playing each one.")

          if env.settings.walkingMode {
            Text(permissionNote)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }

          // Speed control — same SettingsStore the Settings tab writes, so the two screens can't
          // disagree.
          Menu {
            ForEach(SettingsStore.availablePlaybackSpeeds, id: \.self) { speed in
              Button("\(speed.formatted())×") {
                env.settings.defaultPlaybackSpeed = speed
                env.audio.setRate(Float(speed))
              }
            }
          } label: {
            Label(
              "\(env.settings.defaultPlaybackSpeed.formatted())× Speed",
              systemImage: "speedometer"
            )
            .font(.footnote)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.15))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
          }

          // Temporary Slice 11 debug — delete once device testing no longer needs a fake approach.
          Button("Simulate pura approach") {
            simulateRandomPuraApproach()
          }
          .buttonStyle(.bordered)
          .disabled(state != .idle)
          .accessibilityHint("Picks a random Pura site and fires the consent prompt as if you walked up to it.")

          // Temporary until Slice 14 — screen Play / Dismiss so you aren't stuck on AirPods or timeout.
          if state == .prompting, let prompt {
            VStack(spacing: 12) {
              Text(prompt.spokenText)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

              HStack(spacing: 12) {
                Button("Play now") {
                  env.narration.accept(promptID: prompt.id)
                }
                .buttonStyle(.borderedProminent)

                Button("Dismiss", role: .destructive) {
                  env.narration.dismiss(promptID: prompt.id)
                }
                .buttonStyle(.bordered)
              }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Story prompt for \(prompt.siteName)")
          }

          Text("\(env.content.siteCount) sites loaded")
            .font(.footnote)
            .foregroundStyle(.tertiary)
        }
      }
      .padding()
      .navigationTitle("Now")
    }
  }

  /// Among sites whose slug starts with `pura-` (Maospahit, Jagatnatha, Batur Jati). Goes through
  /// `proximity.simulateTrigger`, so history + the consent coordinator see the same callbacks as GPS.
  private func simulateRandomPuraApproach() {
    let puras = env.content.allSites().filter { $0.slug.hasPrefix("pura-") }
    guard let site = puras.randomElement() else { return }
    env.proximity.simulateTrigger(site: site)
  }

  private func statusLine(state: NarrationState, prompt: PendingPrompt?) -> String {
    switch state {
    case .prompting:
      return prompt.map { "Approaching \($0.siteName)" }
        ?? "Story nearby — play or dismiss?"
    case .playing:
      return env.audio.currentStory.map { "Playing \($0.title)" } ?? "Playing…"
    case .idle:
      break
    }
    guard env.settings.walkingMode else { return "Walking mode is off" }
    return env.proximity.isListening
      ? "Listening for nearby stories"
      : "Starting up…"
  }

  /// Honest about what walking mode can actually do given the permission granted: iOS can't be
  /// downgraded from code, and "While Using" can't survive the app being terminated. Silence should
  /// always be explained rather than left a mystery.
  private var permissionNote: String {
    switch env.proximity.authorizationStatus {
    case .authorizedAlways:
      return "Listening in the background — stories can trigger with the screen locked."
    case .authorizedWhenInUse:
      return
        "Listening only while \(AppConfig.appName) is open. Grant “Always” in iOS Settings to hear stories with the app in your pocket."
    case .denied, .restricted:
      return
        "Location is off for \(AppConfig.appName). Turn it on in iOS Settings to hear anything."
    default:
      return "Checking location access…"
    }
  }
}

/// Opens an `any NarrationCoordinator` existential into a generic so Observation tracks the
/// concrete `@Observable` coordinator. Without this, TTS can speak while the Now UI stays idle.
private struct ObservingNarration<Content: View>: View {
  let coordinator: any NarrationCoordinator
  @ViewBuilder let content: (NarrationState, PendingPrompt?) -> Content

  var body: some View {
    observe(coordinator)
  }

  private func observe<C: NarrationCoordinator>(_ coordinator: C) -> Content {
    content(coordinator.state, coordinator.pendingPrompt)
  }
}

#Preview {
  NowView().environment(AppEnvironment())
}
