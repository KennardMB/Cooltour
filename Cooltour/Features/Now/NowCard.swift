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
  /// Identity for the loaded story — resets scrub state when a new site takes over.
  let storyID: String
  let onTogglePlayback: () -> Void
  let onSkipBack: () -> Void
  let onSkipForward: () -> Void
  /// Progress fraction 0…1 — the card stays free of duration math beyond the time label.
  let onSeek: (Double) -> Void
  let onSelectSpeed: (Double) -> Void

  /// Local thumb position. Slider always binds here; we mirror `progress` only while not dragging
  /// so the system Slider can't latch onto a stale value after scrub (asymmetric Binding gotcha).
  @State private var isScrubbing = false
  @State private var displayProgress: Double = 0

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
        Slider(
          value: $displayProgress,
          in: 0...1,
          onEditingChanged: { editing in
            isScrubbing = editing
            if !editing {
              onSeek(displayProgress)
            }
          }
        )
        .disabled(isLoading)
        .accessibilityLabel("Playback position")

        Text(Self.timeText(progress: displayProgress, durationSeconds: durationSeconds))
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

      TranscriptDisclosure(transcript: transcript)
    }
    .padding()
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    .onAppear {
      displayProgress = min(max(0, progress.isFinite ? progress : 0), 1)
    }
    .onChange(of: progress) { _, newValue in
      // Follow live playback (and ±10s seeks) unless the user is dragging the thumb.
      guard !isScrubbing else { return }
      displayProgress = min(max(0, newValue.isFinite ? newValue : 0), 1)
    }
    .onChange(of: storyID) { _, _ in
      isScrubbing = false
      displayProgress = 0
    }
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
    storyID: "pura-maospahit",
    onTogglePlayback: {},
    onSkipBack: {},
    onSkipForward: {},
    onSeek: { _ in },
    onSelectSpeed: { _ in }
  )
  .padding()
}
