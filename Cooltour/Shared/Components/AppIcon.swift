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

    public var assetName: String {
        rawValue
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

#Preview("App Icons") {
    VStack(spacing: 20) {
        Text("Brush Audio & Navigation Icons")
            .appFont(.heading3)

        HStack(spacing: 24) {
            AppIcon(.rewind10, size: 36)
            AppIcon(.play, size: 44)
            AppIcon(.pause, size: 44)
            AppIcon(.forward10, size: 36)
        }

        HStack(spacing: 24) {
            AppIcon(.playbackSpeed, size: 32)
            AppIcon(.queue, size: 32)
            AppIcon(.arrowDown, size: 24)
            AppIcon(.arrowUp, size: 24)
        }
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
