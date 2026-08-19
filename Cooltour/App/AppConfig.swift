import Foundation

enum AppConfig {
  static let appName = "Cooltour"

  static let contentPackName = "denpasar"

  static let defaultTriggerRadiusMeters: Double = 60

  /// Above this horizontal accuracy the fix is too vague to name a site, so we stay silent.
  static let maxLocationAccuracyMeters: Double = 35

  /// A site only re-arms once the user is this much past its radius, so standing on the
  /// boundary with a jittery fix can't fire the same story twice.
  static let reArmRadiusMultiplier: Double = 1.35

  /// Region monitoring wakes the app; it doesn't decide anything. Core Location's geofences are
  /// only dependable around 100 m and up, so the wake ring is wider than any trigger radius —
  /// the precise fix that follows still has to pass the accuracy gate before a story plays.
  static let monitorWakeRadiusMeters: Double = 150

  /// Persisted opt-in for background listening — the storage behind walking mode. Off until the
  /// user asks for it: turning it on is what prompts for "Always" location. The key is shared
  /// rather than private to `SettingsStore` because `CooltourApp` and `CoreLocationProximityEngine`
  /// read it straight from `UserDefaults` at launch, where no view exists to reach the store.
  /// The string value is intentionally left unchanged across the rename so the existing persisted
  /// opt-in survives.
  static let walkingModeKey = "backgroundTriggeringEnabled"

  /// How long a spoken prompt waits for an answer before it gives up and stays silent. Injected
  /// into the coordinator as a `Duration` in tests so they resolve it without sleeping 20s.
  static let consentTimeoutSeconds: Double = 20

  static let usePHASE = false
  static let headingRefinement = false
}
