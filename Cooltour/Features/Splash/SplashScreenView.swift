import Lottie
import SwiftUI

/// Animated splash screen overlay that plays the brand intro animation
/// on initial launch and when returning from the app switcher.
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(red: 29/255, green: 82/255, blue: 216/255) // Brand Blue #1D52D8
                .ignoresSafeArea()

            LottieView(animation: .named("splash screen blue"))
                .playing(loopMode: .loop)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 380, maxHeight: 380)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
