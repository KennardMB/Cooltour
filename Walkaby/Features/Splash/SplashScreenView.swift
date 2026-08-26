import Lottie
import SwiftUI

// MARK: - Splash Screen View (Figma Node 243:1551)
/// Animated splash screen overlay that plays the brand intro animation
/// on initial launch and when returning from the app switcher.
struct SplashScreenView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                Spacer()

                // Animated Walking Footprints
                LottieView(animation: .named("splash screen blue"))
                    .playing(loopMode: .loop)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)

                // Tagline Caption
                Text("Wander without Wonder with")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                // App Brand Name (Baru Lagi 32pt)
                Text("Walkaby")
                    .font(.custom("Baru Lagi", size: 32))
                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultTiledBackground(scale: 0.20)
        .ignoresSafeArea()
    }
}

#Preview {
    SplashScreenView()
}
