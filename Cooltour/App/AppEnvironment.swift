import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let content: any ContentStore
    let audio: any AudioPlayerService
    let proximity: any ProximityEngine
    let notifications: any NotificationService
    let permissions: PermissionCoordinator

    init(
        content: any ContentStore = LocalContentStore.inMemory(),
        audio: any AudioPlayerService = MockAudioPlayerService(),
        proximity: any ProximityEngine = MockProximityEngine(),
        notifications: any NotificationService = MockNotificationService(),
        permissions: PermissionCoordinator = PermissionCoordinator()
    ) {
        self.content = content
        self.audio = audio
        self.proximity = proximity
        self.notifications = notifications

        // The one place proximity meets playback. Auto-play reads a static flag until the
        // real preference store lands in Slice 7.
        self.proximity.onTrigger = { _, story in
            guard AppConfig.autoPlayDefault else { return }
            audio.play(story: story)
        }
    }
}
