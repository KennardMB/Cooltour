import Foundation

/// How an approach prompt was resolved. Replaces the old `wasAutoPlayed` Bool on `TriggerEvent`
/// (Slice 11): once a story must be consented to, there are more than two outcomes. Stored as its
/// raw `String` on the SwiftData model. `pending` is the value at trigger time before the user has
/// answered; `queued` arrives with Slice 11.5.
enum PromptOutcome: String, Codable, Sendable, CaseIterable {
  case pending
  case played
  case dismissed
  case timedOut
}
