import Lottie
import SwiftUI

// MARK: - Onboarding Screen 2 View (Figma Node 245:1747)
/// Second onboarding screen explaining the metal detector discovery mechanism.
public struct OnboardingScreen2View: View {
    public var onNext: (() -> Void)?

    public init(onNext: (() -> Void)? = nil) {
        self.onNext = onNext
    }

    public var body: some View {
        ZStack {
            // 1. Grid Background Texture (Figma Tile Background #F8F7F4)
            TiledBackgroundView()
                .ignoresSafeArea()

            // 2. Main Content
            VStack(alignment: .leading, spacing: 0) {
                // Top Header (Figma Nodes 245:1770 & 245:1769)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(AppConfig.appName) is here!")
                        .font(.custom("Baru Lagi", size: 32))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8

                    Text("Wander without wonder")
                        .font(.custom("Baru Lagi", size: 20))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer(minLength: 12)

                // Animated Illustration (Figma Node 245:1803)
                LottieView(animation: .named("onboarding screen 2"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 400)
                    .accessibilityLabel("Illustration of the app detecting cultural sites")

                Spacer(minLength: 16)

                // Description Block (Figma Node 245:1771)
                VStack(alignment: .leading, spacing: 12) {
                    // Subtitle (Figma Node 245:1772)
                    Text("Works like a metal detector ")
                        .font(.custom("Baru Lagi", size: 20))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Caption Copy with highlighted action text (Figma Node 245:1773)
                    (Text("Just ")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                    + Text("click Explore")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))
                    + Text(" to uncover more about them.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // Primary "Next" Action Button (Figma Node 245:1776, matching Start Exploration in NowView)
                Button {
                    onNext?()
                } label: {
                    ZStack {
                        Image("BrushButtonBlue")
                            .resizable()
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)

                        Text("Next")
                            .font(.custom("Baru Lagi", size: 16))
                            .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255)) // #FEFEFE
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next")
                .accessibilityHint("Proceeds to the next step")
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}

#Preview("Onboarding Screen 2") {
    OnboardingScreen2View()
}
