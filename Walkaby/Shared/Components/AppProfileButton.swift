import SwiftUI

// MARK: - App Profile Button

public struct AppProfileButton: View {
    private let initial: String
    private let action: () -> Void

    public init(initial: String = "A", action: @escaping () -> Void) {
        self.initial = initial
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Image("BrushProfile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppDimension.avatarSize, height: AppDimension.avatarSize)

                Text(initial)
                    .appFont(.heading3, color: AppColor.Brand.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile: \(initial)")
        .accessibilityHint("Opens profile or settings")
    }
}

// MARK: - Previews

#Preview("Profile Button") {
    HStack(spacing: 16) {
        AppProfileButton(initial: "A") {}
        AppProfileButton(initial: "N") {}
        AppProfileButton(initial: "K") {}
    }
    .padding(24)
    .background(AppColor.Background.canvas)
}
