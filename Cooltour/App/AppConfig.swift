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

  static let autoPlayDefault = true
  static let usePHASE = false
  static let headingRefinement = false
}
