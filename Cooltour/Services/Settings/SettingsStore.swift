import Foundation

@MainActor
@Observable
final class SettingsStore {
    static let availablePlaybackSpeeds: [Double] = [0.75, 1.0, 1.25, 1.5]

    var defaultPlaybackSpeed: Double {
        didSet {
            defaults.set(defaultPlaybackSpeed, forKey: speedKey)
        }
    }

    /// The single walking-mode switch (Slice 11). On means the app listens for nearby stories —
    /// including with the screen locked and after the app is terminated — and escalates to
    /// "Always" location; off tears all of that down. It replaces the old auto-play preference
    /// (nothing plays now without being consented to) and absorbs the separate background-
    /// triggering toggle. Persisted under `AppConfig.walkingModeKey` rather than this store's own
    /// key namespace, because `CooltourApp` and `CoreLocationProximityEngine` read it straight from
    /// `UserDefaults` — Core Location can relaunch the app into the background where no view, and
    /// so no environment, ever exists to reach this store.
    var walkingMode: Bool {
        didSet {
            defaults.set(walkingMode, forKey: AppConfig.walkingModeKey)
        }
    }

    private let defaults: UserDefaults
    private let speedKey = "cooltour_default_playback_speed"

    init(
        defaults: UserDefaults = .standard,
        defaultSpeed: Double = 1.0
    ) {
        self.defaults = defaults

        if defaults.object(forKey: speedKey) != nil {
            let savedSpeed = defaults.double(forKey: speedKey)
            self.defaultPlaybackSpeed = savedSpeed > 0 ? savedSpeed : defaultSpeed
        } else {
            self.defaultPlaybackSpeed = defaultSpeed
        }

        // Absent reads as false — walking mode stays off until the user turns it on.
        self.walkingMode = defaults.bool(forKey: AppConfig.walkingModeKey)
    }
}
