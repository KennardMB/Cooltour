import Foundation

/// Latest session truth the phone pushes to the Watch. Latest-wins via
/// `WCSession.updateApplicationContext` — not a GPS firehose (Slice 17–18).
nonisolated struct WatchSessionSnapshot: Equatable, Sendable, Codable {
  var walkingModeEnabled: Bool
  var narrationState: NarrationState
  var pendingPrompt: PendingPrompt?
  var dismissCountdownSeconds: Int?
  var nowPlayingSiteName: String?
  var nowPlayingStoryTitle: String?
  var wayfindingTarget: WayfindingTarget?
  /// Same family as `ConsentStrings` / in-app language override.
  var languageCode: String
}
