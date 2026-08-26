import Lottie
import SwiftUI

// MARK: - Now Hero Illustration (Figma Node 223:1344 / 243:1477)
/// Hand-drawn illustration showing a traveler walking past cultural sites.
/// Uses static illustration before exploration begins, and animated Lottie during active exploration.
public struct NowHeroIllustrationView: View {
    public var isAnimated: Bool

    public init(isAnimated: Bool = true) {
        self.isAnimated = isAnimated
    }

    public var body: some View {
        if isAnimated {
            LottieView(animation: .named("looking for sites"))
                .playing(loopMode: .loop)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        } else {
            Image("NowViewIllustrationStatic")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Animated") {
    NowHeroIllustrationView(isAnimated: true)
}

#Preview("Static") {
    NowHeroIllustrationView(isAnimated: false)
}
