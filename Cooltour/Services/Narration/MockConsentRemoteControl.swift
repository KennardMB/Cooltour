import Foundation

/// Records arm/disarm state so tests can prove the stem is armed only while a prompt is pending and
/// disarmed the moment it resolves, and exposes `simulateStemPress()` to fire the handler without
/// any MediaPlayer hardware.
final class MockConsentRemoteControl: ConsentRemoteControl {
  private(set) var isArmed = false
  private(set) var armedTitle: String?
  private var onPlay: (() -> Void)?

  func arm(title: String, onPlay: @escaping () -> Void) {
    isArmed = true
    armedTitle = title
    self.onPlay = onPlay
  }

  func disarm() {
    isArmed = false
    armedTitle = nil
    onPlay = nil
  }

  /// Test affordance: simulate the AirPod stem squeeze while armed.
  func simulateStemPress() {
    onPlay?()
  }
}
