import AVFoundation

/// `AVSpeechSynthesizer`-backed prompt voice — on-device, offline, no network, matching the
/// offline-first rule. Uses the system default voice; the prompt is four-word wayfinding, not
/// narration, so a produced clip would be wrong here (13 sites × 4 directions can't be pre-recorded).
final class SystemPromptVoice: NSObject, PromptVoice, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  var onFinished: (() -> Void)?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  func speak(_ text: String, languageCode: String) {
    // Replace any in-flight utterance so a new prompt doesn't stack.
    synthesizer.stopSpeaking(at: .immediate)
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice =
      AVSpeechSynthesisVoice(language: languageCode)
      ?? AVSpeechSynthesisVoice(language: "en")
    synthesizer.speak(utterance)
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
  }

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in
      self.onFinished?()
    }
  }
}
