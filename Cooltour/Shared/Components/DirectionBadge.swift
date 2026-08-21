import SwiftUI

// MARK: - Direction Badge

public struct DirectionBadge: View {
    public enum Direction {
        case left
        case right
        case ahead
        case behind

        var iconType: AppIconType? {
            switch self {
            case .left: return .directionLeft
            case .right: return .directionRight
            case .ahead, .behind: return nil
            }
        }
    }

    public let text: String
    public let direction: Direction?

    public init(
        _ text: String,
        direction: Direction? = nil
    ) {
        self.text = text
        self.direction = direction
    }

    public var body: some View {
        HStack(spacing: AppSpacing.xs) {
            if let direction, let iconType = direction.iconType {
                AppIcon(iconType, size: 18)
            }

            Text(text)
                .appFont(.label, color: AppColor.Text.secondary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(AppColor.Background.pure)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .strokeBorder(AppColor.Background.border, lineWidth: AppBorderWidth.thin)
        )
    }
}

// MARK: - Previews

#Preview("Direction Badge") {
    VStack(spacing: 12) {
        DirectionBadge("80m · on your left", direction: .left)
        DirectionBadge("120m · on your right", direction: .right)
        DirectionBadge("40m · just ahead", direction: .ahead)
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
