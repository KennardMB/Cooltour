import SwiftUI

// MARK: - App Button Styles

public struct AppPrimaryButtonStyle: ButtonStyle {
    public enum Size {
        case large
        case small

        var height: CGFloat {
            switch self {
            case .large: return AppDimension.buttonHeightLarge
            case .small: return AppDimension.buttonHeightSmall
            }
        }

        var textStyle: AppTextStyle {
            switch self {
            case .large: return .heading3
            case .small: return .title
            }
        }
    }

    public let size: Size
    public let fullWidth: Bool

    public init(size: Size = .large, fullWidth: Bool = true) {
        self.size = size
        self.fullWidth = fullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        AppPrimaryButtonContent(configuration: configuration, size: size, fullWidth: fullWidth)
    }
}

private struct AppPrimaryButtonContent: View {
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyle.Configuration
    let size: AppPrimaryButtonStyle.Size
    let fullWidth: Bool

    var body: some View {
        configuration.label
            .appFont(size.textStyle)
            .foregroundStyle(textColor(isPressed: configuration.isPressed))
            .padding(.horizontal, AppSpacing.lg)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .strokeBorder(borderColor(isPressed: configuration.isPressed), lineWidth: AppBorderWidth.standard)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return AppColor.Brand.tint
        }
        return isPressed ? AppColor.Brand.dark : AppColor.Brand.primary
    }

    private func borderColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return AppColor.Background.pure
        }
        return AppColor.Brand.dark
    }

    private func textColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return AppColor.Background.muted
        }
        return isPressed ? AppColor.Background.border : AppColor.Background.pure
    }
}

// MARK: - App Button View Helper

public struct AppButton: View {
    public enum Variant {
        case standard(title: String, systemImage: String? = nil)
        case startExploration
        case pauseExploration
    }

    private let variant: Variant
    private let size: AppPrimaryButtonStyle.Size
    private let fullWidth: Bool
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(
        _ title: String,
        systemImage: String? = nil,
        size: AppPrimaryButtonStyle.Size = .large,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.variant = .standard(title: title, systemImage: systemImage)
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
    }

    public init(
        variant: Variant,
        size: AppPrimaryButtonStyle.Size = .large,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.variant = variant
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        switch variant {
        case .startExploration:
            Button(action: action) {
                Group {
                    if !isEnabled {
                        Image("BrushButtonDefaultDisabled")
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image("BrushButtonPlayActive")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(maxHeight: size.height)
            }
            .buttonStyle(BrushButtonPressStyle())

        case .pauseExploration:
            Button(action: action) {
                Image("BrushButtonPauseActive")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: size.height)
            }
            .buttonStyle(BrushButtonPressStyle())

        case .standard(let title, let systemImage):
            Button(action: action) {
                HStack(spacing: AppSpacing.md) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: size == .large ? 20 : 16, weight: .bold))
                    }
                    Text(title)
                }
            }
            .buttonStyle(AppPrimaryButtonStyle(size: size, fullWidth: fullWidth))
        }
    }
}

// MARK: - Brush Button Press Style

private struct BrushButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                if configuration.isPressed {
                    Image("BrushButtonDefaultPressed")
                        .resizable()
                        .scaledToFit()
                }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Square Icon Button (60x60pt)

public struct AppIconButton: View {
    public enum IconType {
        case play
        case pause
        case custom(systemImage: String, label: String)
    }

    private let iconType: IconType
    private let action: () -> Void

    public init(
        _ iconType: IconType,
        action: @escaping () -> Void
    ) {
        self.iconType = iconType
        self.action = action
    }

    public init(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.iconType = .custom(systemImage: systemImage, label: accessibilityLabel)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            switch iconType {
            case .play:
                Image("BrushIconButtonPlay")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppDimension.iconButtonSize, height: AppDimension.iconButtonSize)
            case .pause:
                Image("BrushIconButtonPause")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppDimension.iconButtonSize, height: AppDimension.iconButtonSize)
            case .custom(let systemImage, _):
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .frame(width: AppDimension.iconButtonSize, height: AppDimension.iconButtonSize)
                    .background(AppColor.Brand.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.standard)
                            .strokeBorder(AppColor.Brand.dark, lineWidth: AppBorderWidth.standard)
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch iconType {
        case .play: return "Play story"
        case .pause: return "Pause story"
        case .custom(_, let label): return label
        }
    }
}

// MARK: - Previews

#Preview("App Buttons") {
    VStack(spacing: 20) {
        AppButton(variant: .startExploration) {}
        AppButton(variant: .pauseExploration) {}
//        AppButton("Custom title action", systemImage: "sparkles") {}
//        AppButton("Compact action", size: .small, fullWidth: false) {}
        HStack(spacing: 16) {
            AppIconButton(.play) {}
            AppIconButton(.pause) {}
//            AppIconButton(systemImage: "forward.fill", accessibilityLabel: "Forward") {}
        }
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
