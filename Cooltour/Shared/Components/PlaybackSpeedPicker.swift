import SwiftUI

// MARK: - Playback Speed Options

public enum PlaybackSpeed: Double, CaseIterable, Sendable, Identifiable {
    case half = 0.5
    case threeQuarters = 0.75
    case normal = 1.0
    case oneAndQuarter = 1.25
    case oneAndHalf = 1.5

    public var id: Double { rawValue }

    public var label: String {
        switch self {
        case .half: return "0.5x"
        case .threeQuarters: return "0.75x"
        case .normal: return "1x"
        case .oneAndQuarter: return "1.25x"
        case .oneAndHalf: return "1.5x"
        }
    }

    public var assetName: String {
        switch self {
        case .half: return "BrushSpeedOption0_5"
        case .threeQuarters: return "BrushSpeedOption0_75"
        case .normal: return "BrushSpeedOption1_0"
        case .oneAndQuarter: return "BrushSpeedOption1_25"
        case .oneAndHalf: return "BrushSpeedOption1_5"
        }
    }

    public var iconType: AppIconType {
        AppIconType.forSpeed(rawValue)
    }

    public static func nearest(to value: Double) -> PlaybackSpeed {
        var closest = PlaybackSpeed.normal
        var minDiff = Double.infinity
        for speed in allCases {
            let diff = abs(speed.rawValue - value)
            if diff < minDiff {
                minDiff = diff
                closest = speed
            }
        }
        return closest
    }
}

// MARK: - Playback Speed Horizontal Slider Component

public struct PlaybackSpeedPicker: View {
    @Binding public var selectedSpeed: Double
    public let onSelect: ((Double) -> Void)?

    public init(
        selectedSpeed: Binding<Double>,
        onSelect: ((Double) -> Void)? = nil
    ) {
        self._selectedSpeed = selectedSpeed
        self.onSelect = onSelect
    }

    private var currentOption: PlaybackSpeed {
        PlaybackSpeed.nearest(to: selectedSpeed)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pre-rendered brush slider artwork
                Image(currentOption.assetName)
                    .resizable()
                    .scaledToFit()

                // Interactive tap/drag horizontal zones
                HStack(spacing: 0) {
                    ForEach(PlaybackSpeed.allCases) { speed in
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                updateSpeed(speed.rawValue)
                            }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = max(0, min(value.location.x / geometry.size.width, 1.0))
                        let stepCount = PlaybackSpeed.allCases.count
                        let stepIndex = min(Int(fraction * CGFloat(stepCount)), stepCount - 1)
                        let targetSpeed = PlaybackSpeed.allCases[stepIndex].rawValue
                        if abs(selectedSpeed - targetSpeed) > 0.01 {
                            updateSpeed(targetSpeed)
                        }
                    }
            )
        }
        .frame(height: 84)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback speed")
        .accessibilityValue(currentOption.label)
        .accessibilityAdjustableAction { direction in
            let all = PlaybackSpeed.allCases
            guard let currentIndex = all.firstIndex(of: currentOption) else { return }
            switch direction {
            case .increment:
                if currentIndex < all.count - 1 {
                    updateSpeed(all[currentIndex + 1].rawValue)
                }
            case .decrement:
                if currentIndex > 0 {
                    updateSpeed(all[currentIndex - 1].rawValue)
                }
            @unknown default:
                break
            }
        }
    }

    private func updateSpeed(_ speed: Double) {
        selectedSpeed = speed
        onSelect?(speed)
    }
}

// MARK: - Playback Speed Sheet Component (Figma Node 210:1033)

public struct PlaybackSpeedSheet: View {
    @Binding public var selectedSpeed: Double
    public let onSelect: ((Double) -> Void)?
    public let onClose: (() -> Void)?

    public init(
        selectedSpeed: Binding<Double>,
        onSelect: ((Double) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self._selectedSpeed = selectedSpeed
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Header Row (Title + Close Button)
            HStack {
                Text("Playback Speed")
                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 22))
                    .foregroundStyle(Color(red: 57/255, green: 57/255, blue: 57/255))

                Spacer()

                if let onClose {
                    Button(action: onClose) {
                        AppIcon(.close, size: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close speed picker")
                }
            }
            .padding(.horizontal, AppSpacing.xs)

            // Horizontal Speed Slider
            PlaybackSpeedPicker(selectedSpeed: $selectedSpeed, onSelect: onSelect)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 356)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color(red: 231/255, green: 231/255, blue: 231/255), lineWidth: 4) // #E7E7E7
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Previews

#Preview("Playback Speed Picker") {
    VStack(spacing: 32) {
        Text("Horizontal Speed Slider")
            .appFont(.heading2)

        PlaybackSpeedPicker(selectedSpeed: .constant(1.0))
            .padding(.horizontal, 20)

        PlaybackSpeedSheet(selectedSpeed: .constant(1.25), onClose: {})
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
