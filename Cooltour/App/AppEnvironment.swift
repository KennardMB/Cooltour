import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let content: any ContentStore
    let audio: any AudioPlayerService
    let proximity: any ProximityEngine
    let notifications: any NotificationService
    let settings: SettingsStore

    init(
        content: any ContentStore = LocalContentStore.inMemory(),
        audio: any AudioPlayerService = MockAudioPlayerService(),
        proximity: any ProximityEngine = MockProximityEngine(),
        notifications: any NotificationService = MockNotificationService(),
        settings: SettingsStore = SettingsStore()
    ) {
        self.content = content
        self.audio = audio
        self.proximity = proximity
        self.notifications = notifications
        self.settings = settings

        // Apply persisted default playback speed to audio player
        self.audio.setRate(Float(settings.defaultPlaybackSpeed))

        // Auto-play is controlled by persistent user setting in SettingsStore.
        self.proximity.onTrigger = { _, story in
            guard settings.autoPlay else { return }
            audio.play(story: story)
        }
    }
}
