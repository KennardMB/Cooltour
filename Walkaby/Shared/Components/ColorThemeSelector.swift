import SwiftUI

// MARK: - Cultural Color Theme Option

public enum CulturalColorTheme: String, CaseIterable, Identifiable, Sendable {
    case blue = "Royal Azure"
    case pink = "Pink Carnation"
    case green = "Jade Green"
    case yellow = "Bright Gold"
    case orange = "Tiger Flame"

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

    /// Normalized center-X position (0.0 ... 1.0) on the BrushColorChooseOptions SVG (359x35).
    public var relativeCenterX: CGFloat {
        switch self {
        case .blue:   return 17.36 / 359.0
        case .pink:   return 98.36 / 359.0
        case .green:  return 179.36 / 359.0
        case .yellow: return 260.36 / 359.0
        case .orange: return 341.36 / 359.0
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
        GeometryReader { geometry in
            let width = geometry.size.width
//            let circleSize: CGFloat = 35

            ZStack(alignment: .leading) {
                // 1. Authentic Brush-stroke Color Palette Artwork
                Image("BrushColorChooseOptions")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)

                // 2. Animated Checkmark Indicator positioned over selected circle
                AppIcon(.check, size: 22)
                    .offset(x: width * selectedTheme.relativeCenterX - 11, y: 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTheme)

                // 3. 5 Interactive Tap Areas
                HStack(spacing: 0) {
                    ForEach(CulturalColorTheme.allCases) { theme in
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTheme = theme
                                onSelect?(theme)
                            }
                            .accessibilityElement()
                            .accessibilityLabel("\(theme.rawValue) theme")
                            .accessibilityAddTraits(selectedTheme == theme ? [.isSelected] : [])
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Previews

#Preview("Color Theme Selector") {
    VStack(spacing: 32) {
        Text("Cultural Theme Selector")
            .appFont(.heading3)

        ColorThemeSelector(selectedTheme: .constant(.blue))
        ColorThemeSelector(selectedTheme: .constant(.green))
        ColorThemeSelector(selectedTheme: .constant(.orange))
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
