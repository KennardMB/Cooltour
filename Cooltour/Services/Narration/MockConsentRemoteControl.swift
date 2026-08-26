import Foundation

/// Records arm/disarm state so tests can prove the stem is armed only while a prompt is pending and
/// disarmed the moment it resolves, and exposes `simulateStemPress()` to fire the handler without
/// any MediaPlayer hardware.
final class MockConsentRemoteControl: ConsentRemoteControl {
  private(set) var isArmed = false
  private(set) var armedTitle: String?
  private var onPlay: (() -> Void)?
  private var onQueue: (() -> Void)?

  func arm(
    title: String,
    onPlay: @escaping () -> Void,
    onQueue: (() -> Void)? = nil
  ) {
    isArmed = true
    armedTitle = title
    self.onPlay = onPlay
    self.onQueue = onQueue
  }

  func disarm() {
    isArmed = false
    armedTitle = nil
    onPlay = nil
    onQueue = nil
  }

  /// Test affordance: simulate the AirPod stem single squeeze (play now) while armed.
  func simulateStemPress() {
    onPlay?()
  }

  /// Test affordance: simulate the AirPod stem double squeeze (add to queue) while armed.
  func simulateDoubleStemPress() {
    onQueue?()
  }
}
