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

  /// Off until the user asks for it: turning it on is what prompts for "Always" location.
  /// `SettingsStore` owns this value; the key is shared rather than private to the store
  /// because `CooltourApp` and `CoreLocationProximityEngine` read it straight from
  /// `UserDefaults` at launch, where no view exists to reach the store.
  static let backgroundTriggeringKey = "backgroundTriggeringEnabled"

  /// Seeds `SettingsStore` on first launch only. Read the store, not this, for the
  /// live value — the user can change it in Settings.
  static let autoPlayDefault = true
  static let usePHASE = false
  static let headingRefinement = false
}
