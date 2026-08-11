import Foundation

enum AppConfig {
    static let appName = "Cooltour"

    static let contentPackName = "denpasar"

    static let defaultTriggerRadiusMeters: Double = 60

    /// Above this horizontal accuracy the fix is too vague to name a site, so we stay silent.
    static let maxLocationAccuracyMeters: Double = 35

    static let autoPlayDefault = true
    static let usePHASE = false
    static let headingRefinement = false
}
