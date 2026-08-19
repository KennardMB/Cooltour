import Foundation

/// Records what it was asked to say so tests can assert the exact wording without a speaker, and
/// counts `stop` calls so they can prove a cancelled or answered prompt cuts the voice.
final class MockPromptVoice: PromptVoice {
  private(set) var spokenTexts: [String] = []
  private(set) var stopCount = 0
  var lastSpoken: String? { spokenTexts.last }

  func speak(_ text: String) { spokenTexts.append(text) }
  func stop() { stopCount += 1 }
}
