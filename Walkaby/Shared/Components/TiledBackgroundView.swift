import SwiftUI

// MARK: - Tiled Background Style

public enum TiledBackgroundStyle: Sendable, Equatable {
    /// Default neutral screen canvas (#F8F7F4) with subtle tile grid.
    case `default`
    /// Cultural theme tint for special screens (e.g. My Exploration).
    case theme(CulturalColorTheme)

    public var baseColor: Color {
        switch self {
        case .default:
            return AppColor.Background.canvas // #F8F7F4
        case .theme(let theme):
            switch theme {
            case .blue:   return Color(red: 232/255, green: 238/255, blue: 251/255) // #E8EEFB
            case .pink:   return Color(red: 255/255, green: 230/255, blue: 240/255) // #FFE6F0
            case .green:  return Color(red: 227/255, green: 247/255, blue: 236/255) // #E3F7EC
            case .yellow: return Color(red: 254/255, green: 249/255, blue: 224/255) // #FEF9E0
            case .orange: return Color(red: 255/255, green: 236/255, blue: 229/255) // #FFECE5
            }
        }
    }

    public var tileOpacity: Double {
        switch self {
        case .default: return 0.65
        case .theme:   return 1.0
        }
    }

    public var tileColorMultiplier: Color {
        switch self {
        case .default:
            return Color.white
        case .theme(let theme):
            switch theme {
            case .blue:   return Color(red: 232/255, green: 238/255, blue: 251/255) // #E8EEFB
            case .pink:   return Color(red: 1.0, green: 0.88, blue: 0.94) // #FFE0F0
            case .green:  return Color(red: 0.88, green: 0.98, blue: 0.92) // #E0FAE9
            case .yellow: return Color(red: 1.0, green: 0.97, blue: 0.86) // #FFF7DC
            case .orange: return Color(red: 1.0, green: 0.91, blue: 0.87) // #FFE8DE
            }
        }
    }
}

// MARK: - Tiled Background View

public struct TiledBackgroundView: View {
    /// Base Figma tile artwork dimension (176.0 pt in Figma design space).
    public static let figmaBaseTileDimension: CGFloat = 176.0

    public let style: TiledBackgroundStyle
    /// Figma tile scaling percentage (e.g. 0.20 = 20% -> 35.2pt tile, 0.60 = 60% -> 105.6pt tile).
    public let scale: Double
    /// Optional explicit tiles per row override if specified.
    private let explicitTilesPerRow: Int?

    public init(style: TiledBackgroundStyle = .default, scale: Double = 0.20) {
        self.style = style
        self.scale = scale
        self.explicitTilesPerRow = nil
    }

    public init(theme: CulturalColorTheme, scale: Double = 0.60) {
        self.style = .theme(theme)
        self.scale = scale
        self.explicitTilesPerRow = nil
    }

    public init(style: TiledBackgroundStyle = .default, tilesPerRow: Int) {
        self.style = style
        self.scale = 0.20
        self.explicitTilesPerRow = max(1, tilesPerRow)
    }

    public init(theme: CulturalColorTheme, tilesPerRow: Int) {
        self.style = .theme(theme)
        self.scale = 0.60
        self.explicitTilesPerRow = max(1, tilesPerRow)
    }

    public var body: some View {
        ZStack {
            // 1. Base canvas background color
            style.baseColor
                .ignoresSafeArea()

            // 2. Dynamic scaled grid of brush tiles
            GeometryReader { geometry in
                let tileSize: CGFloat = {
                    if let explicit = explicitTilesPerRow {
                        return geometry.size.width / CGFloat(explicit)
                    } else {
                        // 1:1 Figma percentage scaling (e.g. 20% -> 35.2pt, 60% -> 105.6pt)
                        return max(10, Self.figmaBaseTileDimension * CGFloat(scale))
                    }
                }()

                let columns = Int(ceil(geometry.size.width / tileSize)) + 1
                let rows = Int(ceil(geometry.size.height / tileSize)) + 1

                VStack(spacing: 0) {
                    ForEach(0..<rows, id: \.self) { _ in
                        HStack(spacing: 0) {
                            ForEach(0..<columns, id: \.self) { _ in
                                Image("BrushBackgroundTile")
                                    .resizable()
                                    .scaledToFit()
                                    .colorMultiply(style.tileColorMultiplier)
                                    .opacity(style.tileOpacity)
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Embeds the view inside the default neutral tiled canvas (#F8F7F4) with custom tile scale (default 20% = 0.20).
    public func defaultTiledBackground(scale: Double = 0.20) -> some View {
        ZStack {
            TiledBackgroundView(style: .default, scale: scale)
            self
        }
    }

    /// Embeds the view inside the default neutral tiled canvas with a specific number of tiles per row.
    public func defaultTiledBackground(tilesPerRow: Int) -> some View {
        ZStack {
            TiledBackgroundView(style: .default, tilesPerRow: tilesPerRow)
            self
        }
    }

    /// Embeds the view inside the authentic tiled cultural background with custom tile scale.
    public func culturalTiledBackground(style: TiledBackgroundStyle = .default, scale: Double = 0.20) -> some View {
        ZStack {
            TiledBackgroundView(style: style, scale: scale)
            self
        }
    }

    /// Embeds the view inside a specific themed cultural background (default 60% = 0.60 for celebratory views).
    public func culturalTiledBackground(theme: CulturalColorTheme, scale: Double = 0.60) -> some View {
        ZStack {
            TiledBackgroundView(theme: theme, scale: scale)
            self
        }
    }

    /// Embeds the view inside a specific themed cultural background specifying tiles per row.
    public func culturalTiledBackground(theme: CulturalColorTheme, tilesPerRow: Int) -> some View {
        ZStack {
            TiledBackgroundView(theme: theme, tilesPerRow: tilesPerRow)
            self
        }
    }
}

// MARK: - Previews

#Preview("Tiled Backgrounds (Exact Figma Match)") {
    TabView {
        VStack(spacing: 20) {
            Text("Default Canvas (20% Scale)")
                .appFont(.heading1, color: AppColor.Text.primary)
            Text("Tile: 35.2pt (11+1 cropped tiles across)")
                .appFont(.heading3, color: AppColor.Text.secondary)
        }
        .defaultTiledBackground(scale: 0.20)
        .tabItem { Text("20% (Default)") }

        VStack(spacing: 20) {
            Text("Celebration View (60% Scale)")
                .appFont(.heading1, color: AppColor.Text.primary)
            Text("Tile: 105.6pt (3+1 horizontal, 5+1 vertical)")
                .appFont(.heading3, color: AppColor.Accent.blue)
        }
        .culturalTiledBackground(theme: .blue, scale: 0.60)
        .tabItem { Text("60% (Blue)") }
    }
}
