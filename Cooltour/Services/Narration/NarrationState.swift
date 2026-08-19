import Foundation

/// Where the consent flow is right now. Kept deliberately small: `offeringMore` (Slice 15) and any
/// queue state (Slice 11.5) arrive with the slices that need them rather than being scaffolded now.
enum NarrationState: Equatable, Sendable {
  /// Nothing pending. A new trigger is free to raise a prompt.
  case idle
  /// A prompt is waiting for an answer — from the AirPod stem, a notification, or the screen.
  case prompting
  /// The coordinator has handed a story to the player and hasn't returned to idle yet.
  /// `audio.isPlaying` remains the source of truth for playback itself.
  case playing
}
