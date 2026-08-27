import Foundation

/// A prompt reduced to a flat, `Sendable` value so a notification body, an on-screen card, or the
/// Watch can render it without a `ModelContainer` — the coordinator keeps the real `Story`
/// privately for playback. Same reason `ProximityFix` and `NearbySite` are plain structs alongside
/// the SwiftData models they summarize. `Codable` for WatchConnectivity snapshots (Slice 17).
nonisolated struct PendingPrompt: Identifiable, Equatable, Sendable, Codable {
  let id: UUID
  let siteSlug: String
  let siteName: String
  /// Notification subtitle / Now Playing artist. Empty only if the pack omitted it.
  let districtName: String
  let storySlug: String
  let storyTitle: String
  /// Nil when travel direction isn't trustworthy — the phrase is then omitted from `spokenText`
  /// rather than guessed (Slice 12). Stubbed nil until then.
  let directionPhrase: String?
  /// What `PromptVoice` speaks aloud, precomputed so every answer surface shows the same wording.
  /// Travels on the Watch snapshot; the Watch must not render it (PRD §8.2).
  let spokenText: String
}
