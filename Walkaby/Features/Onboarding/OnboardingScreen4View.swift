import SwiftUI

// MARK: - Onboarding Screen 4 View (Figma Node 245:1819)
/// Fourth onboarding screen prompting the user to enter their name with a 20-character limit.
public struct OnboardingScreen4View: View {
    @AppStorage("user_profile_name") private var storedUserName: String = "Anton B."
    @State private var nameInput: String = ""

    private let maxNameCharacters: Int = 20
    public var onNext: ((String) -> Void)?

    public init(initialName: String = "", onNext: ((String) -> Void)? = nil) {
        self._nameInput = State(initialValue: initialName)
        self.onNext = onNext
    }

    private var isButtonDisabled: Bool {
        nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        ZStack {
            // 1. Grid Background Texture (Figma Tile Background #F8F7F4)
            TiledBackgroundView()
                .ignoresSafeArea()

            // 2. Main Content
            VStack(spacing: 0) {
                // Top Header (Figma Node 245:1825)
                Text("Name?")
                    .font(.custom("Baru Lagi", size: 32))
                    .foregroundStyle(Color(red: 29/255, green: 82/255, blue: 216/255)) // #1D52D8
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 16)

                Spacer(minLength: 16)

                // Illustration of traveler with backpack (Figma Node 245:2070)
                Image("TravelerBackpack")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 244, height: 298)
                    .accessibilityLabel("Illustration of a traveler with a backpack")

                Spacer(minLength: 24)

                // Interactive Name Input Form (Figma Nodes 245:1845 - 245:1847)
                VStack(spacing: 8) {
                    ZStack {
                        // Placeholder
                        if nameInput.isEmpty {
                            Text("e.g., tami")
                                .font(.custom("Baru Lagi", size: 32))
                                .foregroundStyle(Color(red: 226/255, green: 225/255, blue: 222/255)) // #E2E1DE
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        // Text Field
                        TextField("", text: $nameInput)
                            .font(.custom("Baru Lagi", size: 32))
                            .foregroundStyle(Color(red: 17/255, green: 17/255, blue: 17/255))
                            .multilineTextAlignment(.center)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .onChange(of: nameInput) { _, newValue in
                                if newValue.count > maxNameCharacters {
                                    nameInput = String(newValue.prefix(maxNameCharacters))
                                }
                            }
                    }
                    .frame(height: 44)

                    // Hand-drawn Underline Bar (Figma Node 245:1847)
                    Rectangle()
                        .fill(Color(red: 17/255, green: 17/255, blue: 17/255))
                        .frame(height: 2.5)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)

                // Primary "Next" Action Button (Figma Node 245:1823)
                Button {
                    handleNext()
                } label: {
                    ZStack {
                        if isButtonDisabled {
                            Image("BrushButtonDefaultDisabled")
                                .resizable()
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                        } else {
                            Image("BrushButtonBlue")
                                .resizable()
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                        }

                        Text("Next")
                            .font(.custom("Baru Lagi", size: 16))
                            .foregroundStyle(Color(red: 254/255, green: 254/255, blue: 254/255)) // #FEFEFE
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .buttonStyle(.plain)
                .disabled(isButtonDisabled)
                .accessibilityLabel("Next")
                .accessibilityHint(isButtonDisabled ? "Enter your name to continue" : "Proceeds to the next step")
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }

    private func handleNext() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        storedUserName = trimmed
        onNext?(trimmed)
    }
}

#Preview("Onboarding Screen 4 - Empty") {
    OnboardingScreen4View()
}

#Preview("Onboarding Screen 4 - Filled") {
    OnboardingScreen4View(initialName: "Tami")
}
