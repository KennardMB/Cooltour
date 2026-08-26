import Foundation

/// When the Watch should fire approach (A) or play-start (B) haptics from a new snapshot.
enum WatchHapticPolicy {
  /// Fire Haptic A when a *new* pending prompt id arrives. Countdown ticks and identical
  /// redeliveries must not buzz again.
  static func shouldPlayApproachHaptic(
    previousPromptID: UUID?,
    snapshot: WatchSessionSnapshot
  ) -> UUID? {
    guard snapshot.narrationState == .prompting,
      let id = snapshot.pendingPrompt?.id,
      id != previousPromptID
    else { return nil }
    return id
  }

  /// Fire Haptic B when wayfinding arms or the site slug changes — not on clear, not on queue-only.
  static func shouldPlayPlayStartHaptic(
    previousTargetSlug: String?,
    snapshot: WatchSessionSnapshot
  ) -> String? {
    guard let slug = snapshot.wayfindingTarget?.siteSlug, slug != previousTargetSlug else {
      return nil
    }
    return slug
  }
}
