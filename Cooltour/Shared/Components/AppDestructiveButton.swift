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

        var activeAssetName: String {
            switch self {
            case .large: return "BrushButtonDestructiveActiveLarge"
            case .small: return "BrushButtonDestructiveActiveSmall"
            }
        }

        var pressedAssetName: String {
            switch self {
            case .large: return "BrushButtonDestructivePressedLarge"
            case .small: return "BrushButtonDestructivePressedSmall"
            }
        }

        var disabledAssetName: String {
            switch self {
            case .large: return "BrushButtonDestructiveDisabledLarge"
            case .small: return "BrushButtonDestructiveDisabledSmall"
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
        ZStack {
            // Authentic Brush Background Asset
            Image(currentAssetName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(height: size.height)

            // Label & Content
            configuration.label
                .appFont(size.textStyle, color: AppColor.Background.pure)
                .padding(.horizontal, AppSpacing.lg)
        }
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }

    private var currentAssetName: String {
        if !isEnabled {
            return size.disabledAssetName
        }
        return configuration.isPressed ? size.pressedAssetName : size.activeAssetName
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
        Button(action: action) {
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
        AppDestructiveButton("", systemImage: "") {}
        AppDestructiveButton("", size: .small, fullWidth: false) {}
        AppDestructiveButton("") {}
            .disabled(true)
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
