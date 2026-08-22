import CoreLocation
import SwiftUI

struct NowView: View {
  @Environment(AppEnvironment.self) private var env
  @State private var isShowingSitesPlayer: Bool = false

  var body: some View {
    @Bindable var settings = env.settings

    NavigationStack {
      // Opens existentials so Observation tracks concrete `@Observable` types.
      ObservingNarration(coordinator: env.narration) { state, prompt, countdown in
        ObservingQueue(queue: env.storyQueue) { queueItems in
          ObservingAudio(audio: env.audio) { isPlaying, isLoading, currentStory, progress in
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
              .onChange(of: settings.walkingMode) { _, isOn in
                if isOn {
                  Task {
                    _ = await env.notifications.requestAuthorization()
                  }
                }
              }

            if env.settings.walkingMode {
              Text(permissionNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            // The audio player, shown whenever a story is loaded — playing, or briefly paused
            // while the consent prompt speaks over it. Speed lives here now (the old standalone
            // × Speed menu was dropped); it's reachable only while there's audio to affect.
            if let currentStory {
              NowCard(
                siteName: currentStory.site?.name ?? "",
                distanceMeters: distance(for: currentStory),
                storyTitle: currentStory.title,
                snippet: snippet(for: currentStory),
                transcript: currentStory.transcript,
                isPlaying: isPlaying,
                isLoading: isLoading,
                progress: progress,
                durationSeconds: currentStory.durationSeconds,
                speed: env.settings.defaultPlaybackSpeed,
                onTogglePlayback: {
                  if env.audio.isPlaying {
                    env.audio.pause()
                  } else {
                    env.audio.resume()
                  }
                },
                onSelectSpeed: { speed in
                  env.settings.defaultPlaybackSpeed = speed
                  env.audio.setRate(Float(speed))
                }
              )
              .onTapGesture {
                isShowingSitesPlayer = true
              }
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
                    isShowingSitesPlayer = true
                  }
                  .buttonStyle(.borderedProminent)

                  Button("Add to queue") {
                    env.narration.queue(promptID: prompt.id)
                    isShowingSitesPlayer = true
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
      }
      .padding()
      .navigationTitle("Now")
      .fullScreenCover(isPresented: $isShowingSitesPlayer) {
        SitesPlayerView(onOpenMap: {
          env.selectedTab = .map
        })
      }
    }
  }

  private func simulateRandomPuraApproach() {
    let puras = env.content.allSites().filter { $0.slug.hasPrefix("pura-") }
    guard let site = puras.randomElement() else { return }
    env.proximity.simulateTrigger(site: site)
  }

  /// First line or so of the transcript for the card's preview text.
  private func snippet(for story: Story, limit: Int = 140) -> String {
    guard story.transcript.count > limit else { return story.transcript }
    return String(story.transcript.prefix(limit)) + "…"
  }

  /// Best-effort live distance for the card header — nil when the site isn't in range readings.
  private func distance(for story: Story) -> Double? {
    guard let slug = story.site?.slug else { return nil }
    return env.proximity.nearbySites.first { $0.id == slug }?.distanceMeters
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

#Preview {
  NowView().environment(AppEnvironment())
}
