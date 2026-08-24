import SwiftUI

// MARK: - Exploration Binder Card Theme

public enum BinderCardTheme: String, CaseIterable, Sendable {
    case pink
    case orange
    case blue
    case green
    case yellow

    public var backgroundColor: Color {
        switch self {
        case .pink:   return Color(red: 253/255, green: 135/255, blue: 187/255) // #FD87BB
        case .orange: return Color(red: 255/255, green: 102/255, blue: 52/255)  // #FF6634
        case .blue:   return AppColor.Accent.blue                               // #1D52D8
        case .green:  return AppColor.Accent.green                              // #04D066
        case .yellow: return AppColor.Accent.yellow                             // #F7CE00
        }
    }

    public static func forIndex(_ index: Int) -> BinderCardTheme {
        let themes: [BinderCardTheme] = [.pink, .orange, .blue, .green, .yellow]
        return themes[index % themes.count]
    }
}

// MARK: - Exploration Binder Card Component (Figma Node 202:1287)

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
            // 1. Card Base Surface
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .fill(theme.backgroundColor)

            // 2. Left 3-Hole Binder Punch Cutouts
            VStack(spacing: 12) {
                BinderPunchHole()
                BinderPunchHole()
                BinderPunchHole()
            }
            .padding(.leading, 14)

            // 3. Card Content Area
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.custom(AppTextStyle.customFontPostScriptName, size: 16))
                    .foregroundStyle(AppColor.Background.pure)
                    .lineSpacing(4)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

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
            .padding(.leading, 46)
            .padding(.trailing, 18)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), at \(timeText), on \(dateText)")
    }
}

// MARK: - 3D Binder Punch Hole

private struct BinderPunchHole: View {
    var body: some View {
        ZStack {
            // Hole cutout with subtle inner shadow
            Circle()
                .fill(AppColor.Background.pure)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 1.5)
                )
        }
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
            title: "sabtu sama kean tami nanda nisa shin ke gajah mada",
            timeText: "11.30 AM",
            dateText: "21/12/2025",
            theme: .orange
        )
    }
    .padding(20)
    .background(AppColor.Background.canvas)
}
