import Foundation

/// Records what it was asked to say so tests can assert the exact wording without a speaker, and
/// counts `stop` calls so they can prove a cancelled or answered prompt cuts the voice.
///
/// By default `speak` finishes immediately (starts the dismiss countdown in tests). Call
/// `finishSpeaking()` manually when a test needs to control when the utterance ends; set
/// `autoFinish = false` first.
final class MockPromptVoice: PromptVoice {
  private(set) var spokenTexts: [String] = []
  private(set) var stopCount = 0
  var lastSpoken: String? { spokenTexts.last }
  var onFinished: (() -> Void)?
  /// When false, tests must call `finishSpeaking()` to simulate TTS completion.
  var autoFinish = true
  private var speaking = false

  func speak(_ text: String, languageCode: String) {
    speaking = true
    spokenTexts.append(text)
    if autoFinish {
      speaking = false
      onFinished?()
    }
  }

  func stop() {
    stopCount += 1
    speaking = false
  }

  /// Test affordance: end the current utterance without going through `stop` (so `onFinished` fires).
  func finishSpeaking() {
    guard speaking else { return }
    speaking = false
    onFinished?()
  }
}
