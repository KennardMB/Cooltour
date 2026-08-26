import Foundation

/// When the Watch should post or withdraw a local approach notification (Slices 22–24).
/// System notification haptic stands in for Haptic A while the Watch app is not on screen;
/// tap opens the app onto the consent gate.
enum WatchApproachNotificationPolicy {
  /// Post when a *new* pending prompt arrives. Always post — `willPresent` suppresses the banner
  /// if the glance is already open; skipping the post while "foreground" was dropping wakes.
  static func shouldPost(
    previousPromptID: UUID?,
    snapshot: WatchSessionSnapshot
  ) -> PendingPrompt? {
    guard snapshot.narrationState == .prompting,
      let prompt = snapshot.pendingPrompt,
      prompt.id != previousPromptID
    else { return nil }
    return prompt
  }

  /// Same rule for the lightweight WC wake payload (no full snapshot on the wire).
  static func shouldPostWake(
    previousPromptID: UUID?,
    promptID: UUID
  ) -> Bool {
    promptID != previousPromptID
  }

  /// Custom wrist Haptic A only while the glance is open — notification already buzzes otherwise.
  static func shouldPlayForegroundHaptic(
    previousPromptID: UUID?,
    snapshot: WatchSessionSnapshot,
    isAppInForeground: Bool
  ) -> UUID? {
    guard isAppInForeground else { return nil }
    return WatchHapticPolicy.shouldPlayApproachHaptic(
      previousPromptID: previousPromptID,
      snapshot: snapshot
    )
  }

  /// Withdraw the delivered banner when that prompt is no longer pending.
  static func shouldWithdraw(
    postedPromptID: UUID?,
    snapshot: WatchSessionSnapshot
  ) -> UUID? {
    guard let postedPromptID else { return nil }
    if snapshot.pendingPrompt?.id == postedPromptID {
      return nil
    }
    return postedPromptID
  }
}
