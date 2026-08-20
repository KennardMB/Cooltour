import SwiftUI

// MARK: - Destructive Button Style

public struct AppDestructiveButtonStyle: ButtonStyle {
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
        AppDestructiveButtonContent(configuration: configuration, size: size, fullWidth: fullWidth)
    }
}

private struct AppDestructiveButtonContent: View {
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyle.Configuration
    let size: AppDestructiveButtonStyle.Size
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
            return AppColor.Destructive.tint
        }
        return isPressed ? AppColor.Destructive.dark : AppColor.Destructive.primary
    }

    private func borderColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return AppColor.Background.pure
        }
        return AppColor.Destructive.dark
    }

    private func textColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return AppColor.Background.muted
        }
        return AppColor.Background.pure
    }
}

// MARK: - View Helper

public struct AppDestructiveButton: View {
    private let title: String
    private let systemImage: String?
    private let size: AppDestructiveButtonStyle.Size
    private let fullWidth: Bool
    private let action: () -> Void

    public init(
        _ title: String,
        systemImage: String? = nil,
        size: AppDestructiveButtonStyle.Size = .large,
        fullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(role: .destructive, action: action) {
            HStack(spacing: AppSpacing.md) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: size == .large ? 20 : 16, weight: .bold))
                }
                Text(title)
            }
        }
        .buttonStyle(AppDestructiveButtonStyle(size: size, fullWidth: fullWidth))
    }
}

// MARK: - Previews

#Preview("Destructive Buttons") {
    VStack(spacing: 20) {
        AppDestructiveButton("Dismiss (20s)", systemImage: "xmark") {}
        AppDestructiveButton("Skip story", size: .small, fullWidth: false) {}
        AppDestructiveButton("Disabled action") {}
            .disabled(true)
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
