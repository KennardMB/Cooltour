import Lottie
import SwiftUI

// MARK: - Now Hero Illustration (Figma Node 223:1344 / 243:1477)
/// Animated hand-drawn illustration showing a traveler walking past cultural sites.
public struct NowHeroIllustrationView: View {
    public init() {}

    public var body: some View {
        LottieView(animation: .named("looking for sites"))
            .playing(loopMode: .loop)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    NowHeroIllustrationView()
    .frame(height: .infinity)
}
