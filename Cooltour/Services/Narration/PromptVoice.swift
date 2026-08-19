import Foundation

/// Speaks a short wayfinding prompt aloud. Deliberately tiny — the coordinator shouldn't know or
/// care whether the words come from the speech synthesizer, a test spy, or (later) a wrist. This is
/// the one sanctioned exception to the "pre-produced audio" rule: the prompt names a runtime site
/// and direction that no bundled clip could cover, so it's synthesized on-device; narration stays
/// human-produced audio.
///
/// `stop` exists alongside `speak` so answering or cancelling a prompt before the sentence finishes
/// cuts the voice instead of letting it talk over the story it just launched.
@MainActor
protocol PromptVoice: AnyObject {
  func speak(_ text: String)
  func stop()
}
