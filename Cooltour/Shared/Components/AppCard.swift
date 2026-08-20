import SwiftUI

// MARK: - App Card Container

public struct AppCard<Content: View>: View {
    public enum Style {
        /// Standard 4pt brutalist solid border (#E2E1DE) on pure white canvas.
        case standard
        /// Hand-drawn brush outline (BrushCard SVG asset).
        case brush
    }

    private let title: String?
    private let caption: String?
    private let style: Style
    private let content: Content

    public init(
        title: String? = nil,
        caption: String? = nil,
        style: Style = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.caption = caption
        self.style = style
        self.content = content()
    }

    public init(
        title: String,
        caption: String? = nil,
        style: Style = .standard
    ) where Content == EmptyView {
        self.title = title
        self.caption = caption
        self.style = style
        self.content = EmptyView()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if let title {
                Text(title)
                    .appFont(.title, color: AppColor.Text.primary)
            }

            if let caption {
                Text(caption)
                    .appFont(.label, color: AppColor.Text.secondary)
            }

            if !(Content.self == EmptyView.self) {
                content
                    .padding(.top, (title != nil || caption != nil) ? AppSpacing.xs : 0)
            }
        }
        .padding(AppDimension.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            switch style {
            case .standard:
                AppColor.Background.pure
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
            case .brush:
                Image("BrushCard")
                    .resizable()
                    .scaledToFill()
            }
        }
        .overlay {
            if style == .standard {
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .strokeBorder(AppColor.Background.border, lineWidth: AppBorderWidth.standard)
            }
        }
    }
}

// MARK: - Previews

#Preview("App Card") {
    VStack(spacing: 16) {
        AppCard(title: "Lorem Ipsum", caption: "Standard Style", style: .standard)

        AppCard(title: "Pura Maospahit", caption: "Brush Style", style: .brush) {
            Text("A 14th-century Majapahit-era temple hidden inside a quiet Denpasar neighborhood.")
                .appFont(.captionL, color: AppColor.Text.secondary)
        }
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
