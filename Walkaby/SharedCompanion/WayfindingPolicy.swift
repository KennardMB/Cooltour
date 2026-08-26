import Foundation

/// Arm / clear rules for `WayfindingTarget` (Slice 20). Pure — no WCSession, no Core Location types.
enum WayfindingPolicy {
  static func target(
    siteSlug: String,
    siteName: String,
    latitude: Double,
    longitude: Double,
    triggerRadiusMeters: Double
  ) -> WayfindingTarget {
    WayfindingTarget(
      siteSlug: siteSlug,
      siteName: siteName,
      latitude: latitude,
      longitude: longitude,
      triggerRadiusMeters: triggerRadiusMeters
    )
  }

  /// True when the walker has left the armed site's trigger radius (or the site vanished from the list).
  /// Uses trigger radius — not the 1.35× re-arm ring (that ring is for not re-prompting).
  static func shouldClearAfterLeavingRadius(
    target: WayfindingTarget,
    nearby: [(slug: String, distanceMeters: Double)]
  ) -> Bool {
    guard let match = nearby.first(where: { $0.slug == target.siteSlug }) else {
      return true
    }
    return match.distanceMeters > target.triggerRadiusMeters
  }
}
