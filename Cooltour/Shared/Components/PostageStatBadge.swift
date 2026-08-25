import SwiftUI

// MARK: - Postage Badge Type

public enum PostageBadgeType: Sendable {
    case placesVisited(count: Int)
    case distance(km: Double)
    case custom(icon: AppIconType, value: String, label: String, style: Style)

    public enum Style: Sendable {
        case orange
        case pink

        public func assetName(isTall: Bool = false) -> String {
            switch self {
            case .orange: return isTall ? "BrushPostageTallOrange" : "BrushPostageOrange"
            case .pink:   return isTall ? "BrushPostageTallPink" : "BrushPostagePink"
            }
        }
    }

    public var style: Style {
        switch self {
        case .placesVisited: return .orange
        case .distance:      return .pink
        case .custom(_, _, _, let style): return style
        }
    }

    public var iconType: AppIconType {
        switch self {
        case .placesVisited: return .placeVisited
        case .distance:      return .distance
        case .custom(let icon, _, _, _): return icon
        }
    }

    public var valueText: String {
        switch self {
        case .placesVisited(let count):
            return "\(count)"
        case .distance(let km):
            return String(format: "%.1f Km", km).replacingOccurrences(of: ".", with: ",")
        case .custom(_, let value, _, _):
            return value
        }
    }

    public var labelText: String {
        switch self {
        case .placesVisited: return "Places visited"
        case .distance:      return "Distances"
        case .custom(_, _, let label, _): return label
        }
    }

    public var tallLabelText: String {
        switch self {
        case .placesVisited: return "Places visited"
        case .distance:      return "Distances explored"
        case .custom(_, _, let label, _): return label
        }
    }
}

// MARK: - Postage Stat Badge View

public struct PostageStatBadge: View {
    public enum Layout: Sendable {
        case compact
        case tall
    }

    private let type: PostageBadgeType
    private let layout: Layout

    public init(_ type: PostageBadgeType, layout: Layout = .compact) {
        self.type = type
        self.layout = layout
    }

    public var body: some View {
        switch layout {
        case .compact:
            compactBadge
        case .tall:
            tallBadge
        }
    }

    // MARK: - Compact Variant (Used in Explorations and Details)
    private var compactBadge: some View {
        ZStack {
            Image(type.style.assetName(isTall: false))
                .resizable()
                .scaledToFit()

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

    // MARK: - Tall Variant (Used exclusively in Profile screen per Figma 202:1329)
    private var tallBadge: some View {
        ZStack {
            Image(type.style.assetName(isTall: true))
                .resizable()
                .scaledToFit()

            VStack(alignment: .leading, spacing: 0) {
                // Large Top Icon above text
                AppIcon(type.iconType, size: 52)
                    .padding(.top, 18)

                Spacer(minLength: 12)

                // Metric Value + Descriptive Label at bottom
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.valueText)
                        .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                        .foregroundStyle(AppColor.Background.pure)
                        .lineLimit(1)

                    Text(type.tallLabelText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.Background.pure.opacity(0.95))
                        .lineLimit(1)
                }
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
        }
        .aspectRatio(171.0 / 156.0, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.tallLabelText): \(type.valueText)")
    }
}

// MARK: - Exploration Summary Stats Bar (2 Postage Badges)

public struct ExplorationSummaryStats: View {
    public let placesVisitedCount: Int
    public let distanceKm: Double
    public let layout: PostageStatBadge.Layout

    public init(
        placesVisitedCount: Int,
        distanceKm: Double,
        layout: PostageStatBadge.Layout = .compact
    ) {
        self.placesVisitedCount = placesVisitedCount
        self.distanceKm = distanceKm
        self.layout = layout
    }

    public var body: some View {
        HStack(spacing: 12) {
            PostageStatBadge(.placesVisited(count: placesVisitedCount), layout: layout)
            PostageStatBadge(.distance(km: distanceKm), layout: layout)
        }
    }
}

// MARK: - Previews

#Preview("Postage Stat Badges (Compact & Tall)") {
    VStack(spacing: 24) {
        Text("Compact Layout (Explorations)")
            .appFont(.heading3)

        ExplorationSummaryStats(placesVisitedCount: 11, distanceKm: 7.7, layout: .compact)
            .padding(.horizontal, 20)

        Text("Tall Layout (Profile Screen)")
            .appFont(.heading3)

        ExplorationSummaryStats(placesVisitedCount: 11, distanceKm: 7.7, layout: .tall)
            .padding(.horizontal, 20)
    }
    .padding(.vertical, 24)
    .background(AppColor.Background.canvas)
}
