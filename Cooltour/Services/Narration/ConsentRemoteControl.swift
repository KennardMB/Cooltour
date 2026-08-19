import Foundation

/// Arms the AirPod stem (and the lock-screen transport) as a consent answer path while a prompt is
/// awaiting a reply, and disarms it the instant the prompt resolves.
///
/// Disarming is not optional: a `playCommand` left registered would keep routing the user's
/// play/pause squeeze to us for the rest of the walk instead of back to their music — the same
/// class of leak as an audio session that never deactivates, in a different system.
///
/// Behind a protocol so the coordinator's tests never touch `MPRemoteCommandCenter`, which is a
/// process-wide singleton.
@MainActor
protocol ConsentRemoteControl: AnyObject {
  /// Register a one-shot play handler and show `title` as the pending now-playing item, so a stem
  /// squeeze answers "play now" and the lock screen shows what's on offer.
  func arm(title: String, onPlay: @escaping () -> Void)

  /// Remove the handler and clear the pending now-playing item. Safe to call when not armed.
  func disarm()
}
