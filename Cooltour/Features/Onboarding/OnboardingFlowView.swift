import SwiftUI

// MARK: - Onboarding Flow Container
/// Orchestrates the 5 onboarding screens and marks completion in AppStorage.
public struct OnboardingFlowView: View {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentStep: Int = 1

    public var onFinish: (() -> Void)?

    public init(onFinish: (() -> Void)? = nil) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            switch currentStep {
            case 1:
                OnboardingScreen1View {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 2
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case 2:
                OnboardingScreen2View {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 3
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case 3:
                OnboardingScreen3View {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 4
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case 4:
                OnboardingScreen4View { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = 5
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case 5:
                OnboardingScreen5View {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasCompletedOnboarding = true
                        onFinish?()
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            default:
                EmptyView()
            }
        }
    }
}

#Preview("Onboarding Flow") {
    OnboardingFlowView()
        .environment(AppEnvironment())
}
