import SwiftUI

// MARK: - Reusable List Item Button (Queue & Story Rows)

public struct ListButton: View {
    public let title: String
    public let subtitle: String?
    public let durationText: String?
    public let onPlay: () -> Void
    public let onTap: (() -> Void)?

    public init(
        title: String,
        subtitle: String? = nil,
        durationText: String? = nil,
        onPlay: @escaping () -> Void,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.durationText = durationText
        self.onPlay = onPlay
        self.onTap = onTap
    }

    public var body: some View {
        Button {
            if let onTap {
                onTap()
            } else {
                onPlay()
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Info column
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .appFont(.heading3, color: AppColor.Text.primary)
                        .lineLimit(1)

                    if let subtitle {
                        Text(subtitle)
                            .appFont(.captionS, color: AppColor.Text.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: AppSpacing.sm)

                // Optional duration text
                if let durationText {
                    Text(durationText)
                        .appFont(.captionS, color: AppColor.Text.secondary)
                }

                // Play icon button
                Button(action: onPlay) {
                    AppIcon(.play, size: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play \(title)")
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.Background.pure)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.standard)
                    .strokeBorder(AppColor.Background.border, lineWidth: AppBorderWidth.standard)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle ?? "")")
        .accessibilityHint("Tap to play or view details")
    }
}

// MARK: - Previews

#Preview("List Button") {
    VStack(spacing: 16) {
        ListButton(
            title: "Pura Jagatnatha",
            subtitle: "80m · on your left",
            durationText: "1:45",
            onPlay: {},
            onTap: {}
        )

        ListButton(
            title: "Museum Bali",
            subtitle: "120m · just ahead",
            durationText: "2:10",
            onPlay: {}
        )
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
