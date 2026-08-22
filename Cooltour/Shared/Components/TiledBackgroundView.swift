import SwiftUI

// MARK: - Tiled Cultural Background View

public struct TiledBackgroundView: View {
    public let theme: CulturalColorTheme

    public init(theme: CulturalColorTheme = .blue) {
        self.theme = theme
    }

    public var body: some View {
        ZStack {
            // Base background tint
            baseTint
                .ignoresSafeArea()

            // Dynamic GPU-tiled grid of brush tiles (124x124pt)
            GeometryReader { geometry in
                Image("BrushBackgroundTile")
                    .resizable(resizingMode: .tile)
                    .colorMultiply(tileColorMultiplier)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .ignoresSafeArea()
        }
    }

    private var baseTint: Color {
        switch theme {
        case .blue:   return Color(red: 232/255, green: 238/255, blue: 251/255) // Blue-50
        case .pink:   return Color(red: 255/255, green: 230/255, blue: 240/255)
        case .green:  return Color(red: 227/255, green: 247/255, blue: 236/255)
        case .yellow: return Color(red: 254/255, green: 249/255, blue: 224/255)
        case .orange: return Color(red: 255/255, green: 236/255, blue: 229/255)
        }
    }

    private var tileColorMultiplier: Color {
        switch theme {
        case .blue:   return Color.white
        case .pink:   return Color(red: 1.0, green: 0.88, blue: 0.94)
        case .green:  return Color(red: 0.88, green: 0.98, blue: 0.92)
        case .yellow: return Color(red: 1.0, green: 0.97, blue: 0.86)
        case .orange: return Color(red: 1.0, green: 0.91, blue: 0.87)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Embeds the view inside the authentic tiled cultural background.
    public func culturalTiledBackground(theme: CulturalColorTheme = .blue) -> some View {
        ZStack {
            TiledBackgroundView(theme: theme)
            self
        }
    }
}

// MARK: - Previews

#Preview("Tiled Cultural Backgrounds") {
    TabView {
        ForEach(CulturalColorTheme.allCases) { theme in
            VStack(spacing: 20) {
                Text("Exploration is Done!")
                    .appFont(.heading1, color: AppColor.Text.primary)

                Text(theme.rawValue)
                    .appFont(.heading3, color: theme.color)
            }
            .culturalTiledBackground(theme: theme)
            .tabItem {
                Text(theme.rawValue)
            }
        }
    }
}
