import Foundation

/// When the Watch should post or withdraw a local approach notification (Slices 22–24).
/// System notification haptic stands in for Haptic A while the Watch app is not on screen;
/// tap opens the app onto the consent gate.
enum WatchApproachNotificationPolicy {
  /// Post when a *new* pending prompt arrives and the Watch UI is not active.
  /// Foreground uses the in-app consent card + custom Haptic A instead (no duplicate buzz).
  static func shouldPost(
    previousPromptID: UUID?,
    snapshot: WatchSessionSnapshot,
    isAppInForeground: Bool
  ) -> PendingPrompt? {
    guard !isAppInForeground,
      snapshot.narrationState == .prompting,
      let prompt = snapshot.pendingPrompt,
      prompt.id != previousPromptID
    else { return nil }
    return prompt
  }

  /// Custom wrist Haptic A only while the glance is open — otherwise the notification buzzes.
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
