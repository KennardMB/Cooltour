import SwiftUI

/// The active-or-last-played story. Pure display + a handful of callbacks — no service access,
/// so it can preview and test without `AppEnvironment`.
struct NowCard: View {
  let siteName: String
  let distanceMeters: Double?
  let storyTitle: String
  let snippet: String
  let transcript: String
  let isPlaying: Bool
  let isLoading: Bool
  let progress: Double
  let durationSeconds: Double
  let speed: Double
  let onTogglePlayback: () -> Void
  let onSkipBack: () -> Void
  let onSkipForward: () -> Void
  let onSelectSpeed: (Double) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 2) {
        Text(siteName)
          .font(.headline)
        if let distanceMeters {
          Text(Self.distanceText(distanceMeters))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(storyTitle)
          .font(.title3.weight(.semibold))
        Text(snippet)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      VStack(spacing: 8) {
        ProgressView(value: progress)
        Text(Self.timeText(progress: progress, durationSeconds: durationSeconds))
          .font(.caption)
          .foregroundStyle(.secondary)
          .monospacedDigit()
          .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: 28) {
          Button(action: onSkipBack) {
            Image(systemName: "gobackward.10")
              .font(.title2)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
          .disabled(isLoading)
          .accessibilityLabel("Skip back 10 seconds")

          Button(action: onTogglePlayback) {
            Group {
              if isLoading {
                ProgressView()
              } else {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                  .resizable()
              }
            }
            .frame(width: 64, height: 64)
          }
          .buttonStyle(.plain)
          .disabled(isLoading)
          .accessibilityLabel(isPlaying ? "Pause" : "Play")

          Button(action: onSkipForward) {
            Image(systemName: "goforward.10")
              .font(.title2)
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
          .disabled(isLoading)
          .accessibilityLabel("Skip forward 10 seconds")
        }
        .frame(maxWidth: .infinity)
      }

      SpeedChips(
        speeds: SettingsStore.availablePlaybackSpeeds,
        selected: speed,
        onSelect: onSelectSpeed
      )

      TranscriptDisclosure(transcript: transcript)
    }
    .padding()
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private static func distanceText(_ meters: Double) -> String {
    meters < 1000
      ? "\(Int(meters))m away"
      : String(format: "%.1fkm away", meters / 1000)
  }

  private static func timeText(progress: Double, durationSeconds: Double) -> String {
    let elapsed = (progress.isFinite ? progress : 0) * durationSeconds
    return "\(formattedClock(elapsed)) / \(formattedClock(durationSeconds))"
  }

  private static func formattedClock(_ seconds: Double) -> String {
    let total = max(0, Int(seconds.rounded()))
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

#Preview {
  NowCard(
    siteName: "Pura Maospahit",
    distanceMeters: 42,
    storyTitle: "The temple that survived the quake",
    snippet: "As told by a Kultara guide: this temple has stood since...",
    transcript: "As told by a Kultara guide: this temple has stood since the 14th century...",
    isPlaying: true,
    isLoading: false,
    progress: 0.4,
    durationSeconds: 95,
    speed: 1.0,
    onTogglePlayback: {},
    onSkipBack: {},
    onSkipForward: {},
    onSelectSpeed: { _ in }
  )
  .padding()
}
