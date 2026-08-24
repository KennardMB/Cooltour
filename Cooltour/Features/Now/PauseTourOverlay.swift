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
                    // Resume Button (Blue)
                    Button {
                        onResume()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColor.Brand.primary) // #1D52D8
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color(red: 17/255, green: 49/255, blue: 130/255), lineWidth: 4) // #113182
                                )
                                .frame(height: 60)

                            Text("resume")
                                .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Resume tour")

                    // End Tour Button (Red)
                    Button {
                        onEndTour()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 216/255, green: 29/255, blue: 29/255)) // #D81D1D
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color(red: 130/255, green: 17/255, blue: 17/255), lineWidth: 4) // #821111
                                )
                                .frame(height: 60)

                            Text("end tour")
                                .font(.custom(AppTextStyle.customFontPostScriptName, size: 20))
                                .foregroundStyle(Color.white)
                        }
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
