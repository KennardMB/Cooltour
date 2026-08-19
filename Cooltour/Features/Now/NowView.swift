import CoreLocation
import SwiftUI

struct NowView: View {
  @Environment(AppEnvironment.self) private var env

  var body: some View {
    @Bindable var settings = env.settings

    NavigationStack {
      // Opens existentials so Observation tracks concrete `@Observable` types.
      ObservingNarration(coordinator: env.narration) { state, prompt, countdown in
        ObservingQueue(queue: env.storyQueue) { queueItems in
          VStack(spacing: 24) {
            Text(statusLine(state: state, prompt: prompt))
              .font(.title3)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)

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

            // Temporary Slice 11 debug — allow while playing so you can test the interrupt prompt.
            Button("Simulate pura approach") {
              simulateRandomPuraApproach()
            }
            .buttonStyle(.bordered)
            .disabled(state == .prompting)
            .accessibilityHint("Picks a random Pura site and fires the consent prompt as if you walked up to it.")

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

                  Button("Add to queue") {
                    env.narration.queue(promptID: prompt.id)
                  }
                  .buttonStyle(.bordered)

                  Button(dismissTitle(countdown: countdown), role: .destructive) {
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

            if !queueItems.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                Text("Up next")
                  .font(.headline)
                ForEach(queueItems) { item in
                  HStack {
                    VStack(alignment: .leading, spacing: 2) {
                      Text(item.storyTitle)
                        .font(.subheadline)
                      Text(item.siteName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Remove", role: .destructive) {
                      env.storyQueue.remove(id: item.id)
                    }
                    .font(.caption)
                  }
                  .padding(.vertical, 4)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
              .background(Color.secondary.opacity(0.08))
              .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("\(env.content.siteCount) sites loaded")
              .font(.footnote)
              .foregroundStyle(.tertiary)
          }
        }
      }
      .padding()
      .navigationTitle("Now")
    }
  }

  private func simulateRandomPuraApproach() {
    let puras = env.content.allSites().filter { $0.slug.hasPrefix("pura-") }
    guard let site = puras.randomElement() else { return }
    env.proximity.simulateTrigger(site: site)
  }

  private func dismissTitle(countdown: Int?) -> String {
    if let countdown {
      return "Dismiss (\(countdown))"
    }
    return "Dismiss"
  }

  private func statusLine(state: NarrationState, prompt: PendingPrompt?) -> String {
    switch state {
    case .prompting:
      return prompt.map { "Approaching \($0.siteName)" }
        ?? "Story nearby — play, queue, or dismiss?"
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
/// concrete `@Observable` coordinator.
private struct ObservingNarration<Content: View>: View {
  let coordinator: any NarrationCoordinator
  @ViewBuilder let content: (NarrationState, PendingPrompt?, Int?) -> Content

  var body: some View {
    observe(coordinator)
  }

  private func observe<C: NarrationCoordinator>(_ coordinator: C) -> Content {
    content(coordinator.state, coordinator.pendingPrompt, coordinator.dismissCountdownSeconds)
  }
}

private struct ObservingQueue<Content: View>: View {
  let queue: any StoryQueue
  @ViewBuilder let content: ([QueuedStory]) -> Content

  var body: some View {
    observe(queue)
  }

  private func observe<Q: StoryQueue>(_ queue: Q) -> Content {
    content(queue.items)
  }
}

#Preview {
  NowView().environment(AppEnvironment())
}
