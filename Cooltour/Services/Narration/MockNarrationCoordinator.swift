import Foundation
import Observation

/// Does nothing on its own — the real rules live in `ConsentNarrationCoordinator`.
/// It exists so `AppEnvironment`'s default init has a coordinator for previews and tests, and so
/// Slices 13 and 14 can develop against a stable interface. `simulatePrompt` drives the observable
/// state by hand so a `#Preview` can show every screen state without proximity or audio.
@Observable
final class MockNarrationCoordinator: NarrationCoordinator {
  private(set) var state: NarrationState = .idle
  private(set) var pendingPrompt: PendingPrompt?
  private(set) var dismissCountdownSeconds: Int?
  private(set) var wayfindingTarget: WayfindingTarget?

  func handleTrigger(site: Site, story: Story) {}
  func accept(promptID: UUID) {}
  func dismiss(promptID: UUID) {}
  func queue(promptID: UUID) {}

  func cancelSession() {
    pendingPrompt = nil
    dismissCountdownSeconds = nil
    wayfindingTarget = nil
    state = .idle
  }

  func clearWayfindingTarget() {
    wayfindingTarget = nil
  }

  func selectPlaylistIndex(_ index: Int) {}

  /// Preview/UI affordance only — puts the coordinator into `prompting` with a plausible prompt,
  /// using the same `ApproachPrompt` wording the real coordinator speaks.
  func simulatePrompt(site: Site, story: Story, directionPhrase: String? = nil) {
    pendingPrompt = PendingPrompt(
      id: UUID(),
      siteSlug: site.slug,
      siteName: site.name,
      storySlug: story.slug,
      storyTitle: story.title,
      directionPhrase: directionPhrase,
      spokenText: ApproachPrompt.text(siteName: site.name, directionPhrase: directionPhrase)
    )
    state = .prompting
    dismissCountdownSeconds = 10
  }
}
