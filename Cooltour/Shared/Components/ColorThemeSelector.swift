import SwiftUI

// MARK: - Cultural Color Theme Option

public enum CulturalColorTheme: String, CaseIterable, Identifiable, Sendable {
    case blue = "Royal Azure"
    case pink = "Pink Carnation"
    case yellow = "Bright Gold"
    case orange = "Tiger Flame"
    case green = "Jade Green"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .blue: return AppColor.Accent.blue
        case .pink: return AppColor.Accent.pink
        case .yellow: return AppColor.Accent.yellow
        case .orange: return AppColor.Accent.orange
        case .green: return AppColor.Accent.green
        }
    }

    public var tintColor: Color {
        switch self {
        case .blue: return AppColor.Accent.blueTint
        case .pink: return AppColor.Accent.pinkTint
        case .yellow: return AppColor.Accent.yellowTint
        case .orange: return AppColor.Accent.orangeTint
        case .green: return AppColor.Accent.greenTint
        }
    }
}

// MARK: - Color Theme Selector Component

public struct ColorThemeSelector: View {
    @Binding public var selectedTheme: CulturalColorTheme
    public let onSelect: ((CulturalColorTheme) -> Void)?

    public init(
        selectedTheme: Binding<CulturalColorTheme>,
        onSelect: ((CulturalColorTheme) -> Void)? = nil
    ) {
        self._selectedTheme = selectedTheme
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(CulturalColorTheme.allCases) { theme in
                Button {
                    selectedTheme = theme
                    onSelect?(theme)
                } label: {
                    ZStack {
                        Circle()
                            .fill(theme.color)
                            .frame(width: 44, height: 44)

                        if selectedTheme == theme {
                            Circle()
                                .strokeBorder(AppColor.Background.pure, lineWidth: 3)
                                .frame(width: 44, height: 44)

                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppColor.Background.pure)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(theme.rawValue) theme")
                .accessibilityAddTraits(selectedTheme == theme ? [.isSelected] : [])
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.Background.pure)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.standard)
                .strokeBorder(AppColor.Background.border, lineWidth: AppBorderWidth.standard)
        )
    }
}

// MARK: - Previews

#Preview("Color Theme Selector") {
    ColorThemeSelector(selectedTheme: .constant(.blue))
        .padding(24)
        .background(AppColor.Background.canvas)
}
