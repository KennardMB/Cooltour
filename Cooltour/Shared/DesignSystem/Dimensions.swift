import SwiftUI

// MARK: - App Dimensions & Metrics

public enum AppDimension {
    /// Standard large button height (60pt) — optimized for one-thumb walking interaction.
    public static let buttonHeightLarge: CGFloat = 60
    /// Compact button height (40pt).
    public static let buttonHeightSmall: CGFloat = 40
    /// Standard square icon button size (60x60pt).
    public static let iconButtonSize: CGFloat = 60
    /// Profile avatar badge size (40x40pt).
    public static let avatarSize: CGFloat = 40
    /// Standard card padding (12pt).
    public static let cardPadding: CGFloat = 12
    /// Minimum touch target size for accessibility (44x44pt).
    public static let minTouchTarget: CGFloat = 44
}

// MARK: - Corner Radius Tokens

public enum AppRadius {
    /// Standard brutalist tactile radius (4pt).
    public static let standard: CGFloat = 4
    /// Medium card/sheet radius (8pt).
    public static let medium: CGFloat = 8
    /// Large container radius (12pt).
    public static let large: CGFloat = 12
    /// Fully rounded pill shape (999pt).
    public static let pill: CGFloat = 999
}

// MARK: - Border Width Tokens

public enum AppBorderWidth {
    /// Standard prominent brutalist solid border (4pt).
    public static let standard: CGFloat = 4
    /// Subtle divider border (1pt).
    public static let thin: CGFloat = 1
}

// MARK: - Spacing Scale (4pt Grid)

public enum AppSpacing {
    /// 2pt
    public static let xxs: CGFloat = 2
    /// 4pt
    public static let xs: CGFloat = 4
    /// 8pt
    public static let sm: CGFloat = 8
    /// 12pt
    public static let md: CGFloat = 12
    /// 16pt
    public static let lg: CGFloat = 16
    /// 20pt
    public static let l: CGFloat = 20
    /// 24pt
    public static let xl: CGFloat = 24
    /// 32pt
    public static let xxl: CGFloat = 32
    /// 48pt
    public static let xxxl: CGFloat = 48
    /// 64pt
    public static let huge: CGFloat = 64
}
