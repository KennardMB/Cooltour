import SwiftUI

// MARK: - Onboarding Screen 3 View (Figma Node 245:1805)
/// Third onboarding screen highlighting travel logs, collecting badges, and revisiting visited sites.
public struct OnboardingScreen3View: View {
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
                // Top Header (Figma Node 245:1811)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Explore, collect,\nand revisit")
                        .font(.custom("Baru Lagi", size: 32))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer(minLength: 12)

                // Illustration & Badges Composition (Figma Node 245:1806)
                ZStack {
                    // Center Background Site Cards (Figma Node 245:1807)
                    Image("SiteCard")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 271, height: 248)

                    // Badge Top (Explorer - green sunset badge, Figma Node 245:1818)
                    Image("BadgeExplorer")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(12))
                        .offset(x: 10, y: -96)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 1, y: 2)

                    // Badge Bottom-Left (Traveler Special - blue badge, Figma Node 245:1808)
                    Image("BadgeTravelerSpecial")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 98, height: 98)
                        .rotationEffect(.degrees(12))
                        .offset(x: -94, y: 18)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 1, y: 2)

                    // Badge Bottom-Right (Sunny Side Up - yellow/orange badge, Figma Node 245:1809)
                    Image("BadgeSunnySideUp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-12))
                        .offset(x: 74, y: 38)
                        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 1, y: 2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 360)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Illustration of collected site cards and achievement badges")

                Spacer(minLength: 16)

                // Description Block (Figma Node 245:1812)
                VStack(alignment: .leading, spacing: 12) {
                    // Subtitle (Figma Node 245:1813)
                    Text("Build your travel logs!")
                        .font(.custom("Baru Lagi", size: 20))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Caption Copy (Figma Node 245:1814)
                    Text("We'll save the spots you uncover so you can look back anytime")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // Primary "Next" Action Button (Figma Node 245:1817, matching Start Exploration in NowView)
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

#Preview("Onboarding Screen 3") {
    OnboardingScreen3View()
}
