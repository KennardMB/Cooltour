import SwiftUI

// MARK: - App Text Styles

/// Semantic typography tokens mapping directly to Figma design styles.
public enum AppTextStyle: Sendable {
    /// 32pt Baru Lagi (Line Height: 1.6) — Screen titles, site names
    case heading1
    /// 28pt Baru Lagi (Line Height: 1.4) — Section headers, sheet titles
    case heading2
    /// 20pt Baru Lagi (Line Height: 1.2) — Card titles, primary CTA button labels
    case heading3
    /// 16pt Baru Lagi (Line Height: 1.2) — Cultural badges, small headings
    case title

    /// 24pt SF Pro Rounded Bold — Large system titles
    case titleL
    /// 20pt SF Pro Rounded Semibold — Subheadings, modal titles
    case titleM
    /// 16pt SF Pro Rounded Regular — Primary body copy, transcripts
    case captionL
    /// 14pt SF Pro Rounded Regular — Secondary descriptions, timestamps
    case captionS
    /// 12pt SF Pro Rounded Regular — Metadata, distance tags, chip labels
    case label

    public static let customFontPostScriptName = "BaruLagi-Regular"
    public static let customFontFamilyName = "Baru Lagi"

    /// The baseline font size in points.
    public var pointSize: CGFloat {
        switch self {
        case .heading1: return 32
        case .heading2: return 28
        case .heading3: return 20
        case .title:    return 16
        case .titleL:   return 24
        case .titleM:   return 20
        case .captionL: return 16
        case .captionS: return 14
        case .label:    return 12
        }
    }

    /// Relative Dynamic Type text style for accessible scaling.
    public var dynamicTextStyle: Font.TextStyle {
        switch self {
        case .heading1: return .largeTitle
        case .heading2: return .title
        case .heading3: return .title3
        case .title:    return .headline
        case .titleL:   return .title2
        case .titleM:   return .headline
        case .captionL: return .body
        case .captionS: return .subheadline
        case .label:    return .caption
        }
    }

    /// The SwiftUI `Font` representation.
    public var font: Font {
        switch self {
        case .heading1, .heading2, .heading3, .title:
            return .custom(Self.customFontPostScriptName, size: pointSize, relativeTo: dynamicTextStyle)
        case .titleL:
            return .system(size: pointSize, weight: .bold, design: .rounded)
        case .titleM:
            return .system(size: pointSize, weight: .semibold, design: .rounded)
        case .captionL, .captionS, .label:
            return .system(size: pointSize, weight: .regular, design: .rounded)
        }
    }

    /// Line spacing / height multiplier relative to point size.
    public var lineSpacing: CGFloat {
        switch self {
        case .heading1: return pointSize * 0.6 // 1.6x total line height
        case .heading2: return pointSize * 0.4 // 1.4x total line height
        case .heading3, .title, .titleL, .titleM, .captionL, .captionS, .label:
            return pointSize * 0.2 // 1.2x total line height
        }
    }
}

// MARK: - View Modifier

public struct AppFontModifier: ViewModifier {
    public let style: AppTextStyle
    public let color: Color?

    public init(style: AppTextStyle, color: Color? = nil) {
        self.style = style
        self.color = color
    }

    public func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .ifLet(color) { view, color in
                view.foregroundStyle(color)
            }
    }
}

extension View {
    /// Applies the semantic design system typography style.
    public func appFont(_ style: AppTextStyle, color: Color? = nil) -> some View {
        modifier(AppFontModifier(style: style, color: color))
    }

    @ViewBuilder
    fileprivate func ifLet<T, V: View>(_ value: T?, transform: (Self, T) -> V) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Previews

#Preview("Typography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Heading 1 (32pt)").appFont(.heading1)
            Text("Heading 2 (28pt)").appFont(.heading2)
            Text("Heading 3 (20pt)").appFont(.heading3)
            Text("Title (16pt)").appFont(.title)
            Divider()
            Text("Title-L Rounded (24pt)").appFont(.titleL)
            Text("Title-M Rounded (20pt)").appFont(.titleM)
            Text("Caption-L Rounded (16pt)").appFont(.captionL)
            Text("Caption-S Rounded (14pt)").appFont(.captionS)
            Text("Label Rounded (12pt)").appFont(.label)
        }
        .padding(24)
    }
}
