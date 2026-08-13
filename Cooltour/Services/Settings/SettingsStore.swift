import Foundation

@MainActor
@Observable
final class SettingsStore {
    static let availablePlaybackSpeeds: [Double] = [0.75, 1.0, 1.25, 1.5]

    var autoPlay: Bool {
        didSet {
            defaults.set(autoPlay, forKey: autoPlayKey)
        }
    }

    var defaultPlaybackSpeed: Double {
        didSet {
            defaults.set(defaultPlaybackSpeed, forKey: speedKey)
        }
    }

    /// Persisted under `AppConfig.backgroundTriggeringKey` rather than this store's own
    /// key namespace, because `CooltourApp` and `CoreLocationProximityEngine` read it
    /// straight from `UserDefaults` — Core Location can relaunch the app into the
    /// background where no view, and so no environment, ever exists to reach this store.
    var backgroundTriggering: Bool {
        didSet {
            defaults.set(
                backgroundTriggering,
                forKey: AppConfig.backgroundTriggeringKey
            )
        }
    }

    private let defaults: UserDefaults
    private let autoPlayKey = "cooltour_auto_play"
    private let speedKey = "cooltour_default_playback_speed"

    init(
        defaults: UserDefaults = .standard,
        defaultAutoPlay: Bool = AppConfig.autoPlayDefault,
        defaultSpeed: Double = 1.0
    ) {
        self.defaults = defaults

        if defaults.object(forKey: autoPlayKey) != nil {
            self.autoPlay = defaults.bool(forKey: autoPlayKey)
        } else {
            self.autoPlay = defaultAutoPlay
        }

        if defaults.object(forKey: speedKey) != nil {
            let savedSpeed = defaults.double(forKey: speedKey)
            self.defaultPlaybackSpeed = savedSpeed > 0 ? savedSpeed : defaultSpeed
        } else {
            self.defaultPlaybackSpeed = defaultSpeed
        }

        // No `object(forKey:)` dance: absent reads as false, which is the intended
        // default — background triggering stays off until the user asks for it.
        self.backgroundTriggering = defaults.bool(
            forKey: AppConfig.backgroundTriggeringKey
        )
    }
}
