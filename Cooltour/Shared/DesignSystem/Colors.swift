import SwiftUI

// MARK: - App Color System

/// Semantic color tokens extracted from the Cooltour Figma design system.
public enum AppColor {

    // MARK: - Canvas & Backgrounds
    public enum Background {
        /// Pure surface white (#FEFEFE) for cards, sheets, and elevated elements.
        public static let pure = Color(hex: 0xFEFEFE)
        /// Warm off-white (#F8F7F4) for screen backgrounds.
        public static let canvas = Color(hex: 0xF8F7F4)
        /// Subtle gray border (#E2E1DE) for card outlines and dividers.
        public static let border = Color(hex: 0xE2E1DE)
        /// Deep neutral gray (#686866) for muted elements.
        public static let muted = Color(hex: 0x686866)
    }

    // MARK: - Text & Grays
    public enum Text {
        /// Primary high-contrast text (#111111).
        public static let primary = Color(hex: 0x111111)
        /// Secondary body text and caption (#393939).
        public static let secondary = Color(hex: 0x393939)
        /// Subtle divider and placeholder tint (#E7E7E7).
        public static let subtle = Color(hex: 0xE7E7E7)
    }

    // MARK: - Primary Brand (Royal Azure)
    public enum Brand {
        /// Light blue tint (#E8EEFB) for avatar background, disabled buttons.
        public static let tint = Color(hex: 0xE8EEFB)
        /// Primary brand blue (#1D52D8) for active CTA buttons, active accents.
        public static let primary = Color(hex: 0x1D52D8)
        /// Dark blue (#113182) for 4pt borders and pressed button states.
        public static let dark = Color(hex: 0x113182)
    }

    // MARK: - Destructive (Red)
    public enum Destructive {
        /// Disabled red background tint (#FBE8E8).
        public static let tint = Color(hex: 0xFBE8E8)
        /// Active destructive red (#D81D1D) for dismiss and delete buttons.
        public static let primary = Color(hex: 0xD81D1D)
        /// Pressed / border dark red (#821111) for destructive 4pt borders.
        public static let dark = Color(hex: 0x821111)
    }

    // MARK: - Accent Colors
    public enum Accent {
        /// Royal Azure
        public static let blue = Color(hex: 0x1D52D8)
        public static let blueTint = Color(hex: 0xE8EEFB)
        public static let blueDark = Color(hex: 0x113182)

        /// Pink Carnation
        public static let pink = Color(hex: 0xFD87BB)
        public static let pinkTint = Color(hex: 0xFFE2EF)
        public static let pinkDark = Color(hex: 0x904D6B)

        /// Bright Gold
        public static let yellow = Color(hex: 0xFFD817)
        public static let yellowTint = Color(hex: 0xFFF6C7)
        public static let yellowDark = Color(hex: 0x917B0D)

        /// Tiger Flame
        public static let orange = Color(hex: 0xFF6634)
        public static let orangeTint = Color(hex: 0xFFDACE)
        public static let orangeDark = Color(hex: 0x913A1E)

        /// Jade Green
        public static let green = Color(hex: 0x01B552)
        public static let greenTint = Color(hex: 0xC2EDD5)
        public static let greenDark = Color(hex: 0x01672F)
    }
}

// MARK: - Hex Initializer Helper

extension Color {
    /// Initialize a Color from a 24-bit RGB integer (e.g. `0x1D52D8`).
    public init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Previews

#Preview("Color Palette") {
    ScrollView {
        VStack(spacing: 16) {
            Group {
                Text("Backgrounds").font(.headline)
                HStack {
                    swatch(name: "pure", color: AppColor.Background.pure)
                    swatch(name: "canvas", color: AppColor.Background.canvas)
                    swatch(name: "border", color: AppColor.Background.border)
                    swatch(name: "muted", color: AppColor.Background.muted)
                }
            }

            Group {
                Text("Brand (Blue)").font(.headline)
                HStack {
                    swatch(name: "tint", color: AppColor.Brand.tint)
                    swatch(name: "primary", color: AppColor.Brand.primary)
                    swatch(name: "dark", color: AppColor.Brand.dark)
                }
            }

            Group {
                Text("Destructive (Red)").font(.headline)
                HStack {
                    swatch(name: "tint", color: AppColor.Destructive.tint)
                    swatch(name: "primary", color: AppColor.Destructive.primary)
                    swatch(name: "dark", color: AppColor.Destructive.dark)
                }
            }

            Group {
                Text("Accent Colors").font(.headline)
                HStack {
                    swatch(name: "Yellow", color: AppColor.Accent.yellow)
                    swatch(name: "Pink", color: AppColor.Accent.pink)
                    swatch(name: "Orange", color: AppColor.Accent.orange)
                    swatch(name: "Green", color: AppColor.Accent.green)
                    swatch(name: "Blue", color: AppColor.Accent.blue)
                }
            }
        }
        .padding(24)
    }
}

private func swatch(name: String, color: Color) -> some View {
    VStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColor.Background.border, lineWidth: 1)
            )
        Text(name)
            .font(.caption2)
    }
}
