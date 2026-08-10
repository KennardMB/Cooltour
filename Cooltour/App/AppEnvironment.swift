import SwiftUI

@Observable
final class AppEnvironment {
    let content: any ContentStore
    let audio: any AudioPlayerService
    let proximity: any ProximityEngine
    let notifications: any NotificationService

    init(
        content: any ContentStore = MockContentStore(),
        audio: any AudioPlayerService = MockAudioPlayerService(),
        proximity: any ProximityEngine = MockProximityEngine(),
        notifications: any NotificationService = MockNotificationService()
    ) {
        self.content = content
        self.audio = audio
        self.proximity = proximity
        self.notifications = notifications
    }
}
