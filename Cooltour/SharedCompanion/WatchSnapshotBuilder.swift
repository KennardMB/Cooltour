import Foundation

/// Builds the latest-wins WatchConnectivity snapshot from phone session state (Slice 18).
/// Pure so unit tests need no WCSession.
enum WatchSnapshotBuilder {
  static func make(
    walkingModeEnabled: Bool,
    narrationState: NarrationState,
    pendingPrompt: PendingPrompt?,
    dismissCountdownSeconds: Int?,
    nowPlayingSiteName: String?,
    nowPlayingStoryTitle: String?,
    wayfindingTarget: WayfindingTarget?,
    languageCode: String
  ) -> WatchSessionSnapshot {
    WatchSessionSnapshot(
      walkingModeEnabled: walkingModeEnabled,
      narrationState: narrationState,
      pendingPrompt: pendingPrompt,
      dismissCountdownSeconds: dismissCountdownSeconds,
      nowPlayingSiteName: nowPlayingSiteName,
      nowPlayingStoryTitle: nowPlayingStoryTitle,
      wayfindingTarget: wayfindingTarget,
      languageCode: languageCode
    )
  }
}
