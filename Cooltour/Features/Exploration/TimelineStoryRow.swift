import SwiftUI

// MARK: - Timeline Story Row

/// One site stop on an exploration timeline — shared by details and post-tour EndView.
struct TimelineStoryRow: View {
  let siteName: String
  let storyTitle: String
  let snippet: String
  let isPlaying: Bool
  let isFirst: Bool
  let isLast: Bool
  let onPlayToggle: () -> Void

  private let nodeSize: CGFloat = 18
  private let nodeTopInset: CGFloat = 24

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      // Timeline indicator: bridge top inset into the node, then fill down to the next row.
      VStack(spacing: 0) {
        if isFirst {
          Color.clear.frame(height: nodeTopInset)
        } else {
          Rectangle()
            .fill(AppColor.Brand.primary.opacity(0.35))
            .frame(width: 2, height: nodeTopInset)
        }

        Circle()
          .fill(isPlaying ? AppColor.Brand.primary : AppColor.Background.pure)
          .frame(width: nodeSize, height: nodeSize)
          .overlay(
            Circle()
              .strokeBorder(AppColor.Brand.primary, lineWidth: isPlaying ? 0 : 2)
          )

        if !isLast {
          // Spacer takes remaining row height so the rail reaches the next node.
          Spacer(minLength: 0)
            .frame(width: 2)
            .overlay {
              Rectangle()
                .fill(AppColor.Brand.primary.opacity(0.35))
            }
        }
      }
      .frame(width: 24)
      .frame(maxHeight: .infinity, alignment: .top)

      // Story Card
      HStack(alignment: .center, spacing: AppSpacing.sm) {
        VStack(alignment: .leading, spacing: 4) {
          Text(siteName)
            .font(.custom(AppTextStyle.customFontPostScriptName, size: 18))
            .foregroundStyle(isPlaying ? AppColor.Brand.primary : AppColor.Text.primary)
            .lineLimit(1)

          if !snippet.isEmpty {
            Text(snippet)
              .appFont(.label, color: AppColor.Text.secondary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
          }
        }

        Spacer(minLength: 8)

        Button {
          onPlayToggle()
        } label: {
          AppIcon(isPlaying ? .pause : .play, size: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause story" : "Play story")
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .background(AppColor.Background.pure)
      .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
      .overlay(
        RoundedRectangle(cornerRadius: AppRadius.standard)
          .strokeBorder(
            isPlaying ? AppColor.Brand.primary : AppColor.Background.border,
            lineWidth: isPlaying ? 2 : 1
          )
      )
      .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
      .padding(.bottom, 12)
    }
  }
}
