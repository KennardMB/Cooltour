import SwiftUI

// MARK: - Postage Badge Type

public enum PostageBadgeType: Sendable {
    case placesVisited(count: Int)
    case distance(km: Double)
    case custom(icon: AppIconType, value: String, label: String, style: Style)

    public enum Style: Sendable {
        case orange
        case pink

        var assetName: String {
            switch self {
            case .orange: return "BrushPostageOrange"
            case .pink:   return "BrushPostagePink"
            }
        }
    }

    var style: Style {
        switch self {
        case .placesVisited: return .orange
        case .distance:      return .pink
        case .custom(_, _, _, let style): return style
        }
    }

    var iconType: AppIconType {
        switch self {
        case .placesVisited: return .placeVisited
        case .distance:      return .distance
        case .custom(let icon, _, _, _): return icon
        }
    }

    var valueText: String {
        switch self {
        case .placesVisited(let count):
            return "\(count)"
        case .distance(let km):
            return String(format: "%.1f Km", km).replacingOccurrences(of: ".", with: ",")
        case .custom(_, let value, _, _):
            return value
        }
    }

    var labelText: String {
        switch self {
        case .placesVisited: return "Places visited"
        case .distance:      return "Distances"
        case .custom(_, _, let label, _): return label
        }
    }
}

// MARK: - Postage Stat Badge View

public struct PostageStatBadge: View {
    private let type: PostageBadgeType

    public init(_ type: PostageBadgeType) {
        self.type = type
    }

    public var body: some View {
        ZStack {
            // 1. Authentic Postage / Ticket Scalloped Background Asset
            Image(type.style.assetName)
                .resizable()
                .scaledToFit()

            // 2. Badge Content (Icon + Metric Text)
            HStack(spacing: 8) {
                AppIcon(type.iconType, size: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.valueText)
                        .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                        .foregroundStyle(AppColor.Background.pure)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Text(type.labelText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.Background.pure.opacity(0.95))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 14)
            .padding(.trailing, 8)
            .padding(.top, 14)
            .padding(.bottom, 2)
        }
        .aspectRatio(178.0 / 86.0, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.labelText): \(type.valueText)")
    }
}

// MARK: - Exploration Summary Stats Bar (2 Postage Badges)

public struct ExplorationSummaryStats: View {
    public let placesVisitedCount: Int
    public let distanceKm: Double

    public init(placesVisitedCount: Int, distanceKm: Double) {
        self.placesVisitedCount = placesVisitedCount
        self.distanceKm = distanceKm
    }

    public var body: some View {
        HStack(spacing: 12) {
            PostageStatBadge(.placesVisited(count: placesVisitedCount))
            PostageStatBadge(.distance(km: distanceKm))
        }
    }
}

// MARK: - Previews

#Preview("Postage Stat Badges (Figma Pixel Perfect)") {
    VStack(spacing: 24) {
        Text("Exploration Summary Stats")
            .appFont(.heading3)

        ExplorationSummaryStats(placesVisitedCount: 11, distanceKm: 7.7)
            .padding(.horizontal, 20)

        ExplorationSummaryStats(placesVisitedCount: 4, distanceKm: 2.3)
            .padding(.horizontal, 20)
    }
    .padding(.vertical, 24)
    .background(AppColor.Background.canvas)
}
