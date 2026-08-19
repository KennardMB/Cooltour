import AVFoundation

/// `AVSpeechSynthesizer`-backed prompt voice — on-device, offline, no network, matching the
/// offline-first rule. Uses the system default voice; the prompt is four-word wayfinding, not
/// narration, so a produced clip would be wrong here (13 sites × 4 directions can't be pre-recorded).
final class SystemPromptVoice: PromptVoice {
  private let synthesizer = AVSpeechSynthesizer()

  func speak(_ text: String) {
    let utterance = AVSpeechUtterance(string: text)
    synthesizer.speak(utterance)
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
  }
}
