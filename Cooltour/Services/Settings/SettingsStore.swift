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
    }
}
