import SwiftUI

// MARK: - Brush Audio Scrubber (Figma Node 194:211)

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
                let trackWidth = geometry.size.width
                let thumbWidth: CGFloat = 13
                let thumbOffset = max(0, min((trackWidth - thumbWidth) * CGFloat(activeProgress), trackWidth - thumbWidth))

                ZStack(alignment: .leading) {
                    // 1. White background track frame
                    Image("BrushScrubberTrackWhite")
                        .resizable()
                        .frame(width: trackWidth, height: 13)

                    // 2. Blue progress track frame (clipped by active progress)
                    Image("BrushScrubberTrackBlue")
                        .resizable()
                        .frame(width: trackWidth, height: 13)
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: trackWidth * CGFloat(activeProgress), height: 13)
                        }

                    // 3. Slider position thumb (13x32pt)
                    Image("BrushScrubberThumb")
                        .resizable()
                        .scaledToFit()
                        .frame(width: thumbWidth, height: 32)
                        .offset(x: thumbOffset)
                }
                .frame(height: 32, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isInteractive else { return }
                            isDragging = true
                            let newProgress = Double(max(0, min(value.location.x / trackWidth, 1.0)))
                            dragProgress = newProgress
                        }
                        .onEnded { value in
                            guard isInteractive else { return }
                            let finalProgress = Double(max(0, min(value.location.x / trackWidth, 1.0)))
                            progress = finalProgress
                            isDragging = false
                            onSeek?(finalProgress * durationSeconds)
                        }
                )
            }
            .frame(height: 32)

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
        .accessibilityLabel("Audio progress scrubber")
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

#Preview("Brush Audio Scrubber") {
    VStack(spacing: 32) {
        AudioScrubber(progress: .constant(0.0), durationSeconds: 120)
        AudioScrubber(progress: .constant(0.45), durationSeconds: 145)
        AudioScrubber(progress: .constant(0.85), durationSeconds: 180)
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
