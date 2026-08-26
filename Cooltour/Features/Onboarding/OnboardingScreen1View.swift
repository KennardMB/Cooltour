import Lottie
import SwiftUI

// MARK: - Onboarding Screen 1 View (Figma Node 245:1736)
/// Initial onboarding welcome screen introducing the core proposition of discovering stories while walking.
public struct OnboardingScreen1View: View {
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
                // Top Greeting Header (Figma Node 245:1738)
                Text("Hey there 👋🏻")
                    .font(.custom("Baru Lagi", size: 32))
                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer(minLength: 12)

                // Animated Map & Walking Traveler Illustration (Figma Node 245:1746)
                LottieView(animation: .named("onboarding screen 1"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 360)
                    .accessibilityLabel("Illustration of a traveler exploring a city map")

                Spacer(minLength: 16)

                // Description Block (Figma Node 245:1739)
                VStack(alignment: .leading, spacing: 12) {
                    // Subtitle (Figma Node 245:1740)
                    Text("Is that you, traveler?")
                        .font(.custom("Baru Lagi", size: 20))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Caption Copy (Figma Node 245:1741)
                    Text("Maybe every spot you pass has a story you never knew until now...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // Primary "Next" Action Button (Figma Node 245:1744, matching Start Exploration in NowView)
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

#Preview("Onboarding Screen 1") {
    OnboardingScreen1View()
}
