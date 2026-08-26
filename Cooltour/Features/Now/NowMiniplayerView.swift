import SwiftUI

// MARK: - Now Miniplayer View (Figma Node 271:2454)
/// Floating bottom miniplayer showing the active site/story and playback status with quick play/pause.
public struct NowMiniplayerView: View {
    @Environment(AppEnvironment.self) private var env
    public var onTap: () -> Void

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    private var playheadSite: Site? {
        let playhead = env.playlist.playheadIndex ?? 0
        return env.playlist.site(at: playhead)
    }

    private var playheadStory: Story? {
        let playhead = env.playlist.playheadIndex ?? 0
        return env.playlist.story(at: playhead)
    }

    private var activeStory: Story? {
        if let current = env.audio.currentStory, current.slug == playheadStory?.slug {
            return current
        }
        return playheadStory ?? env.audio.currentStory
    }

    private var siteTitle: String {
        playheadSite?.name ?? activeStory?.title ?? "Cultural Story"
    }

    private var duration: Double {
        max(1.0, activeStory?.durationSeconds(for: env.settings.audioLanguage) ?? 180.0)
    }

    private var currentTime: Double {
        env.audio.progress * duration
    }

    private var remainingTime: Double {
        max(0, duration - currentTime)
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    public var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Story Info (Title + Elapsed/Remaining Time)
                VStack(alignment: .leading, spacing: 4) {
                    Text(siteTitle)
                        .font(.custom("Baru Lagi", size: 16))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .lineLimit(1)

                    Text("\(formatTime(currentTime)) / -\(formatTime(remainingTime))")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                }

                Spacer()

                // Play / Pause Toggle Button (32x32 in Figma Node 271:2454)
                Button {
                    if env.audio.isPlaying {
                        env.audio.pause()
                    } else if env.audio.currentStory != nil {
                        env.audio.resume()
                    } else if let playhead = env.playlist.playheadIndex, env.playlist.carouselEntries.indices.contains(playhead) {
                        env.narration.selectPlaylistIndex(playhead)
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(red: 17/255, green: 49/255, blue: 130/255), lineWidth: 2) // #113182
                            )
                            .frame(width: 32, height: 32)

                        Image(systemName: env.audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255))
                    }
                    .frame(width: 44, height: 44) // Generous hit target
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(env.audio.isPlaying ? "Pause audio" : "Play audio")
            }
            .padding(.horizontal, 20)
            .frame(height: 72)
            .background(Color(red: 254/255, green: 254/255, blue: 254/255)) // #FEFEFE
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color(red: 226/255, green: 225/255, blue: 222/255)), // #E2E1DE
                alignment: .top
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(siteTitle), \(formatTime(currentTime)) of \(formatTime(duration))")
        .accessibilityHint("Tap to expand full player")
    }
}

#Preview {
    NowMiniplayerView(onTap: {})
        .environment(AppEnvironment())
}
