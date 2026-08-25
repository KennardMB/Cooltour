import SwiftUI

// MARK: - Pause Tour Overlay (Figma Node 209:3795)

public struct PauseTourOverlay: View {
    public let onResume: () -> Void
    public let onEndTour: () -> Void

    public init(onResume: @escaping () -> Void, onEndTour: @escaping () -> Void) {
        self.onResume = onResume
        self.onEndTour = onEndTour
    }

    public var body: some View {
        ZStack {
            // Semi-opaque neutral canvas backdrop (#E2E1DE at 96% opacity)
            Color(red: 226/255, green: 225/255, blue: 222/255)
                .opacity(0.96)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("done wandering?")
                        .font(.custom(AppTextStyle.customFontPostScriptName, size: 32))
                        .foregroundStyle(AppColor.Brand.primary) // #1D52D8

                    Text("all the places will be saved once you ended it.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 10/255))
                }
                .frame(width: 354, alignment: .leading)

                HStack(spacing: 12) {
                    // Resume Button (Blue Brush)
                    Button {
                        onResume()
                    } label: {
                        Image("BrushButtonResume")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Resume tour")

                    // End Tour Button (Red Brush)
                    Button {
                        onEndTour()
                    } label: {
                        Image("BrushButtonEndTour")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("End tour")
                }
                .frame(width: 354)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
