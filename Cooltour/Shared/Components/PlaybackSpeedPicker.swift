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
}

// MARK: - Playback Speed Sheet Component

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
        VStack(spacing: AppSpacing.lg) {
            // Header with title and close button
            HStack {
                Text("Playback Speed")
                    .appFont(.heading3, color: AppColor.Text.primary)

                Spacer()

                if let onClose {
                    Button(action: onClose) {
                        AppIcon(.close, size: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close speed picker")
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)

            // Speed options list
            VStack(spacing: AppSpacing.sm) {
                ForEach(PlaybackSpeed.allCases) { speed in
                    Button {
                        selectedSpeed = speed.rawValue
                        onSelect?(speed.rawValue)
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            AppIcon(speed.iconType, size: 32)

                            Text(speed.label)
                                .appFont(.titleM, color: isSelected(speed) ? AppColor.Brand.primary : AppColor.Text.primary)

                            Spacer()

                            if isSelected(speed) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(AppColor.Brand.primary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .frame(height: 56)
                        .background(isSelected(speed) ? AppColor.Brand.tint : AppColor.Background.pure)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.standard)
                                .strokeBorder(
                                    isSelected(speed) ? AppColor.Brand.primary : AppColor.Background.border,
                                    lineWidth: isSelected(speed) ? AppBorderWidth.standard : AppBorderWidth.thin
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(speed.label) playback speed")
                    .accessibilityAddTraits(isSelected(speed) ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.Background.canvas)
    }

    private func isSelected(_ speed: PlaybackSpeed) -> Bool {
        abs(selectedSpeed - speed.rawValue) < 0.05
    }
}

// MARK: - Previews

#Preview("Playback Speed Sheet") {
    PlaybackSpeedSheet(selectedSpeed: .constant(1.0), onClose: {})
}
