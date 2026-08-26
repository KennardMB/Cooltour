import SwiftUI

// MARK: - Exploration Binder Card Theme

public enum BinderCardTheme: String, CaseIterable, Sendable {
    case pink
    case orange
    case blue
    case green
    case yellow

    public var assetName: String {
        switch self {
        case .pink:   return "BrushExplorationPink"
        case .orange: return "BrushExplorationOrange"
        case .green:  return "BrushExplorationGreen"
        case .blue:   return "BrushExplorationBlue"
        case .yellow: return "BrushExplorationYellow"
        }
    }

    public var backgroundColor: Color {
        switch self {
        case .pink:   return Color(red: 253/255, green: 135/255, blue: 187/255) // #FD87BB
        case .orange: return Color(red: 255/255, green: 102/255, blue: 52/255)  // #FF6634
        case .blue:   return AppColor.Accent.blue                               // #1D52D8
        case .green:  return AppColor.Accent.green                              // #01B552
        case .yellow: return AppColor.Accent.yellow                             // #F9CF00
        }
    }

    public static func forIndex(_ index: Int) -> BinderCardTheme {
        let themes: [BinderCardTheme] = [.pink, .orange, .blue, .green, .yellow]
        return themes[index % themes.count]
    }

    public static func fromCulturalColorTheme(_ theme: CulturalColorTheme) -> BinderCardTheme {
        switch theme {
        case .pink:   return .pink
        case .orange: return .orange
        case .green:  return .green
        case .blue:   return .blue
        case .yellow: return .yellow
        }
    }
}

// MARK: - Exploration Binder Card Component (Figma Nodes 202:1287 & 239:1523)

public struct ExplorationBinderCard: View {
    public let title: String
    public let timeText: String
    public let dateText: String
    public let theme: BinderCardTheme

    public init(
        title: String,
        timeText: String,
        dateText: String,
        theme: BinderCardTheme = .pink
    ) {
        self.title = title
        self.timeText = timeText
        self.dateText = dateText
        self.theme = theme
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            // 1. Authentic SVG Card Artwork with 3-hole punch & drop shadow
            Image(theme.assetName)
                .resizable()
                .scaledToFit()

            // 2. Card Content Area
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 16))
                    .foregroundStyle(AppColor.Background.pure)
                    .lineSpacing(3)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)

                HStack {
                    Text(timeText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.Background.pure.opacity(0.95))

                    Spacer()

                    Text(dateText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(AppColor.Background.pure.opacity(0.95))
                }
            }
            .padding(.leading, 50)
            .padding(.trailing, 20)
            .padding(.vertical, 14)
        }
        .aspectRatio(356.0 / 100.0, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), at \(timeText), on \(dateText)")
    }
}

// MARK: - Previews

#Preview("Exploration Binder Cards") {
    VStack(spacing: 20) {
        ExplorationBinderCard(
            title: "sabtu sama kean tami nanda nisa shin ke gajah mada",
            timeText: "11.30 AM",
            dateText: "21/12/2025",
            theme: .pink
        )

        ExplorationBinderCard(
            title: "keliling pasar kumbasari beli canang",
            timeText: "08.15 AM",
            dateText: "22/12/2025",
            theme: .orange
        )

        ExplorationBinderCard(
            title: "jalan sore di kuta liat sunset",
            timeText: "05.45 PM",
            dateText: "23/12/2025",
            theme: .green
        )

        ExplorationBinderCard(
            title: "pura maospahit majapahit denpasar walk",
            timeText: "02.00 PM",
            dateText: "24/12/2025",
            theme: .blue
        )

        ExplorationBinderCard(
            title: "kuliner malam veteran denpasar",
            timeText: "07.30 PM",
            dateText: "25/12/2025",
            theme: .yellow
        )
    }
    .padding(20)
    .background(AppColor.Background.canvas)
}
