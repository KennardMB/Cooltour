import SwiftUI

// MARK: - Onboarding Screen 5 View (Figma Node 245:1877)
/// Fifth onboarding screen requesting location and notification permissions to enable proximity site detection.
public struct OnboardingScreen5View: View {
    @Environment(AppEnvironment.self) private var env
    @AppStorage("user_profile_name") private var userName: String = "Anton B."

    @State private var hasAllowedLocation: Bool = false
    @State private var hasAllowedNotification: Bool = false

    public var onNext: (() -> Void)?

    public init(onNext: (() -> Void)? = nil) {
        self.onNext = onNext
    }

    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "traveler" : trimmed
    }

    public var body: some View {
        ZStack {
            // 1. Grid Background Texture (Figma Tile Background #F8F7F4)
            TiledBackgroundView()
                .ignoresSafeArea()

            // 2. Main Content inside ScrollView for all screen sizes
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top Header (Figma Node 245:1883)
                    Text("Ready to explore,\n\(displayName) ?")
                        .font(.custom("Baru Lagi", size: 32))
                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // Illustration: New Site Detector Alert (Figma Node 245:1884)
                    Image("NewSite")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 190)
                        .accessibilityLabel("Illustration of radar detecting a new site")
                        .padding(.vertical, 12)

                    // Rationale Description (Location + Notification Copy)
                    VStack(spacing: 8) {
                        Text("Your location is how our detector finds hidden stories as you walk.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)

                        Text("Turn on notifications so Walkaby can chime the moment you're near a cultural site!")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    Spacer(minLength: 32)

                    // Action Buttons Stack
                    VStack(spacing: 12) {
                        // 1. Allow Location Button (Blue Brush)
                        Button {
                            handleAllowLocation()
                        } label: {
                            ZStack {
                                if hasAllowedLocation {
                                    Image("BrushButtonDefaultDisabled")
                                        .resizable()
                                        .frame(height: 60)
                                        .frame(maxWidth: .infinity)

                                    Text("Location Allowed ✓")
                                        .font(.custom("Baru Lagi", size: 16))
                                        .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255))
                                } else {
                                    Image("BrushButtonBlue")
                                        .resizable()
                                        .frame(height: 60)
                                        .frame(maxWidth: .infinity)

                                    Text("Allow Location")
                                        .font(.custom("Baru Lagi", size: 16))
                                        .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255)) // #FEFEFE
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                        .disabled(hasAllowedLocation)
                        .accessibilityLabel(hasAllowedLocation ? "Location Allowed" : "Allow Location")
                        .accessibilityHint("Requests GPS location permissions to detect stories while walking")

                        // 2. Allow Notification Button (Orange Brush)
                        Button {
                            handleAllowNotification()
                        } label: {
                            ZStack {
                                if hasAllowedNotification {
                                    Image("BrushButtonDefaultDisabled")
                                        .resizable()
                                        .frame(height: 60)
                                        .frame(maxWidth: .infinity)

                                    Text("Notification Allowed ✓")
                                        .font(.custom("Baru Lagi", size: 16))
                                        .foregroundStyle(Color(red: 196/255, green: 75/255, blue: 37/255))
                                } else {
                                    Image("BrushButtonOrange")
                                        .resizable()
                                        .frame(height: 60)
                                        .frame(maxWidth: .infinity)

                                    Text("Allow Notification")
                                        .font(.custom("Baru Lagi", size: 16))
                                        .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                        .disabled(hasAllowedNotification)
                        .accessibilityLabel(hasAllowedNotification ? "Notification Allowed" : "Allow Notification")
                        .accessibilityHint("Requests notification permissions for nearby site alerts")

                        // 3. Skip / Maybe Later Button (Subtle Row)
                        Button {
                            onNext?()
                        } label: {
                            ZStack {
                                Image("BrushRowButton")
                                    .resizable()
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)

                                Text("Maybe Later")
                                    .font(.custom("Baru Lagi", size: 16))
                                    .foregroundStyle(Color(red: 104/255, green: 104/255, blue: 102/255)) // #686866
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Maybe Later")
                        .accessibilityHint("Proceeds to explore without granting remaining permissions")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private func handleAllowLocation() {
        env.proximity.start()
        withAnimation(.easeInOut(duration: 0.2)) {
            hasAllowedLocation = true
        }
        checkBothGranted()
    }

    private func handleAllowNotification() {
        Task {
            _ = await env.notifications.requestAuthorization()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    hasAllowedNotification = true
                }
                checkBothGranted()
            }
        }
    }

    private func checkBothGranted() {
        if hasAllowedLocation && hasAllowedNotification {
            onNext?()
        }
    }
}

#Preview("Onboarding Screen 5") {
    OnboardingScreen5View()
        .environment(AppEnvironment())
}
