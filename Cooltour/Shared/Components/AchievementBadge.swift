import SwiftUI

// MARK: - Achievement Badge Type

public enum AchievementBadgeType: String, CaseIterable, Sendable {
    case travelerSpecial = "BadgeTravelerSpecial"
    case sunnySideUp = "BadgeSunnySideUp"
    case explorer = "BadgeExplorer"

    public var title: String {
        switch self {
        case .travelerSpecial:
            return "Traveler Special"
        case .sunnySideUp:
            return "Sunny Side Up"
        case .explorer:
            return "Nature Explorer"
        }
    }

    public var description: String {
        switch self {
        case .travelerSpecial:
            return "Unlocked by listening to cultural stories across Denpasar."
        case .sunnySideUp:
            return "Completed a morning exploration walk."
        case .explorer:
            return "Discovered hidden natural and spiritual sanctuaries."
        }
    }

    public var assetName: String {
        rawValue
    }
}

// MARK: - Achievement Badge View

public struct AchievementBadge: View {
    private let type: AchievementBadgeType
    private let size: CGFloat
    private let showTitle: Bool

    public init(
        _ type: AchievementBadgeType,
        size: CGFloat = 80,
        showTitle: Bool = true
    ) {
        self.type = type
        self.size = size
        self.showTitle = showTitle
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(type.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            if showTitle {
                Text(type.title)
                    .appFont(.label, color: AppColor.Text.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.title) badge")
        .accessibilityHint(type.description)
    }
}

// MARK: - Previews

#Preview("Achievement Badges") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Cultural Achievement Badges")
                .appFont(.heading3)

            HStack(spacing: 20) {
                AchievementBadge(.travelerSpecial)
                AchievementBadge(.sunnySideUp)
                AchievementBadge(.explorer)
            }
        }
        .padding(24)
    }
    .background(AppColor.Background.canvas)
}
