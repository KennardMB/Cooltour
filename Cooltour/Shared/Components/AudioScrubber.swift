import SwiftUI

// MARK: - Audio Playback Scrubber

public struct AudioScrubber: View {
    @Binding public var progress: Double // 0.0 ... 1.0
    public let durationSeconds: Double
    public let isInteractive: Bool
    public let onSeek: ((Double) -> Void)?

    @State private var isDragging: Bool = false
    @State private var dragProgress: Double = 0.0

    public init(
        progress: Binding<Double>,
        durationSeconds: Double,
        isInteractive: Bool = true,
        onSeek: ((Double) -> Void)? = nil
    ) {
        self._progress = progress
        self.durationSeconds = durationSeconds
        self.isInteractive = isInteractive
        self.onSeek = onSeek
    }

    private var activeProgress: Double {
        isDragging ? dragProgress : progress
    }

    private var currentSeconds: Double {
        activeProgress * durationSeconds
    }

    public var body: some View {
        VStack(spacing: AppSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .fill(AppColor.Background.border)
                        .frame(height: 6)

                    // Active progress fill
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .fill(AppColor.Brand.primary)
                        .frame(width: max(0, min(geometry.size.width * CGFloat(activeProgress), geometry.size.width)), height: 6)

                    // Slider thumb
                    Circle()
                        .fill(AppColor.Brand.primary)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .strokeBorder(AppColor.Background.pure, lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        .offset(x: max(0, min(geometry.size.width * CGFloat(activeProgress) - 9, geometry.size.width - 18)))
                }
                .frame(height: 24)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isInteractive else { return }
                            isDragging = true
                            let newProgress = Double(max(0, min(value.location.x / geometry.size.width, 1.0)))
                            dragProgress = newProgress
                        }
                        .onEnded { value in
                            guard isInteractive else { return }
                            let finalProgress = Double(max(0, min(value.location.x / geometry.size.width, 1.0)))
                            progress = finalProgress
                            isDragging = false
                            onSeek?(finalProgress * durationSeconds)
                        }
                )
            }
            .frame(height: 24)

            // Timestamps
            HStack {
                Text(formatTime(currentSeconds))
                    .appFont(.captionS, color: AppColor.Text.secondary)

                Spacer()

                Text("-\(formatTime(max(0, durationSeconds - currentSeconds)))")
                    .appFont(.captionS, color: AppColor.Text.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Audio progress")
        .accessibilityValue("\(Int(activeProgress * 100)) percent, \(formatTime(currentSeconds)) of \(formatTime(durationSeconds))")
    }

    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let total = Int(max(0, seconds))
        let minutes = total / 60
        let remaining = total % 60
        return String(format: "%d:%02d", minutes, remaining)
    }
}

// MARK: - Previews

#Preview("Audio Scrubber") {
    VStack(spacing: 24) {
        AudioScrubber(progress: .constant(0.35), durationSeconds: 145)
        AudioScrubber(progress: .constant(0.8), durationSeconds: 60)
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
