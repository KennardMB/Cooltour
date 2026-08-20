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
    private let isUnlocked: Bool
    private let size: CGFloat
    private let showTitle: Bool

    public init(
        _ type: AchievementBadgeType,
        isUnlocked: Bool = true,
        size: CGFloat = 80,
        showTitle: Bool = true
    ) {
        self.type = type
        self.isUnlocked = isUnlocked
        self.size = size
        self.showTitle = showTitle
    }

    public var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Image(type.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .opacity(isUnlocked ? 1.0 : 0.4)
                    .grayscale(isUnlocked ? 0.0 : 0.9)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.25, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)
                        .padding(AppSpacing.xs)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }

            if showTitle {
                Text(type.title)
                    .appFont(.label, color: isUnlocked ? AppColor.Text.primary : AppColor.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.title) badge, \(isUnlocked ? "Unlocked" : "Locked")")
        .accessibilityHint(type.description)
    }
}

// MARK: - Previews

#Preview("Achievement Badges") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Unlocked Badges")
                .appFont(.heading3)

            HStack(spacing: 20) {
                AchievementBadge(.travelerSpecial, isUnlocked: true)
                AchievementBadge(.sunnySideUp, isUnlocked: true)
                AchievementBadge(.explorer, isUnlocked: true)
            }

            Text("Locked State")
                .appFont(.heading3)

            HStack(spacing: 20) {
                AchievementBadge(.travelerSpecial, isUnlocked: false)
                AchievementBadge(.sunnySideUp, isUnlocked: false)
                AchievementBadge(.explorer, isUnlocked: false)
            }
        }
        .padding(24)
    }
    .background(AppColor.Background.canvas)
}
