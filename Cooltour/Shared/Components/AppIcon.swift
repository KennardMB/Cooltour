import SwiftUI

// MARK: - App Icon Token

public enum AppIconType: String, CaseIterable, Sendable {
    case forward10 = "IconForward10"
    case rewind10 = "IconRewind10"
    case playbackSpeed = "IconPlaybackSpeed"
    case queue = "IconQueue"
    case arrowDown = "IconArrowDown"
    case arrowUp = "IconArrowUp"
    case play = "BrushIconButtonPlay"
    case pause = "BrushIconButtonPause"
    case profile = "BrushProfile"
    case directionLeft = "IconDirectionLeft"
    case directionRight = "IconDirectionRight"
    case close = "IconClose"
    case slideHandle = "IconSlideHandle"
    case speed0_5 = "IconSpeed0_5"
    case speed0_75 = "IconSpeed0_75"
    case speed1_0 = "IconSpeed1_0"
    case speed1_25 = "IconSpeed1_25"
    case speed1_5 = "IconSpeed1_5"

    public var assetName: String {
        rawValue
    }

    /// Convenience method mapping playback rate to its corresponding icon.
    public static func forSpeed(_ rate: Double) -> AppIconType {
        switch rate {
        case ..<0.625: return .speed0_5
        case 0.625..<0.875: return .speed0_75
        case 0.875..<1.125: return .speed1_0
        case 1.125..<1.375: return .speed1_25
        default: return .speed1_5
        }
    }
}

// MARK: - App Icon View

public struct AppIcon: View {
    private let type: AppIconType
    private let size: CGFloat?

    public init(_ type: AppIconType, size: CGFloat? = nil) {
        self.type = type
        self.size = size
    }

    public var body: some View {
        Image(type.assetName)
            .resizable()
            .scaledToFit()
            .ifLet(size) { view, s in
                view.frame(width: s, height: s)
            }
    }
}

extension View {
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

#Preview("App Icons Palette") {
    ScrollView {
        VStack(spacing: 24) {
            Text("Audio & Navigation Icons")
                .appFont(.heading3)

            HStack(spacing: 20) {
                AppIcon(.rewind10, size: 36)
                AppIcon(.play, size: 44)
                AppIcon(.pause, size: 44)
                AppIcon(.forward10, size: 36)
            }

            HStack(spacing: 20) {
                AppIcon(.playbackSpeed, size: 32)
                AppIcon(.queue, size: 32)
                AppIcon(.close, size: 28)
                AppIcon(.slideHandle, size: 28)
                AppIcon(.directionLeft, size: 28)
                AppIcon(.directionRight, size: 28)
            }

            Text("Playback Speed Icons")
                .appFont(.heading3)

            HStack(spacing: 16) {
                AppIcon(.speed0_5, size: 36)
                AppIcon(.speed0_75, size: 36)
                AppIcon(.speed1_0, size: 36)
                AppIcon(.speed1_25, size: 36)
                AppIcon(.speed1_5, size: 36)
            }
        }
        .padding(24)
    }
    .background(AppColor.Background.canvas)
}
