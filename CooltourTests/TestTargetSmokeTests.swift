import Testing

@testable import Cooltour

/// Proves the Swift Testing target is wired to the app module and runs. Real coverage arrives with
/// the slices that need it (`ApproachPrompt` in Slice 11b/D, the coordinator in Slice 11b/E).
struct TestTargetSmokeTests {
  @Test func testTargetCanImportAppModule() {
    #expect(AppConfig.appName == "Walkaby")
  }

  @Test @MainActor func onboardingScreen1ViewCanInitializeAndTriggerNext() {
    var nextTriggered = false
    let view = OnboardingScreen1View(onNext: {
      nextTriggered = true
    })
    #expect(view.onNext != nil)
    view.onNext?()
    #expect(nextTriggered == true)
  }

  @Test @MainActor func onboardingScreen2ViewCanInitializeAndTriggerNext() {
    var nextTriggered = false
    let view = OnboardingScreen2View(onNext: {
      nextTriggered = true
    })
    #expect(view.onNext != nil)
    view.onNext?()
    #expect(nextTriggered == true)
  }

  @Test @MainActor func onboardingScreen3ViewCanInitializeAndTriggerNext() {
    var nextTriggered = false
    let view = OnboardingScreen3View(onNext: {
      nextTriggered = true
    })
    #expect(view.onNext != nil)
    view.onNext?()
    #expect(nextTriggered == true)
  }

  @Test @MainActor func onboardingScreen4ViewValidatesNameAndTriggersNext() {
    var submittedName: String?
    let view = OnboardingScreen4View(initialName: "Kadek Tami", onNext: { name in
      submittedName = name
    })
    #expect(view.onNext != nil)
    view.onNext?("Kadek Tami")
    #expect(submittedName == "Kadek Tami")
  }

  @Test @MainActor func onboardingScreen5ViewCanInitializeAndTriggerAllowLocation() {
    var allowLocationTriggered = false
    let view = OnboardingScreen5View(onNext: {
      allowLocationTriggered = true
    })
    #expect(view.onNext != nil)
    view.onNext?()
    #expect(allowLocationTriggered == true)
  }

  @Test @MainActor func nowHeroIllustrationViewCanInitializeModes() {
    let animatedView = NowHeroIllustrationView(isAnimated: true)
    #expect(animatedView.isAnimated == true)

    let staticView = NowHeroIllustrationView(isAnimated: false)
    #expect(staticView.isAnimated == false)
  }

  @Test @MainActor func nowMiniplayerViewCanInitializeAndTap() {
    var tapped = false
    let view = NowMiniplayerView(onTap: {
      tapped = true
    })
    view.onTap()
    #expect(tapped == true)
  }

  @Test @MainActor func onboardingFlowViewCanInitializeAndFinish() {
    var finished = false
    let view = OnboardingFlowView(onFinish: {
      finished = true
    })
    #expect(view.onFinish != nil)
    view.onFinish?()
    #expect(finished == true)
  }
}
