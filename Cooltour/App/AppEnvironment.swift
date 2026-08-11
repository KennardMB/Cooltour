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
        self.permissions = permissions
    }
}
