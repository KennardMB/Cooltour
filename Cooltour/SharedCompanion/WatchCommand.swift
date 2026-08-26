import Foundation

/// Watch → phone intents. Delivered with `sendMessage` so a wrist tap is not lost if the Watch
/// app backgrounds. Stale `promptID` is a no-op on the phone (same rule as notification / stem).
nonisolated enum WatchCommand: Equatable, Sendable, Codable {
  case accept(promptID: UUID)
  case queue(promptID: UUID)
  case dismiss(promptID: UUID)
  case setWalkingMode(Bool)
}
