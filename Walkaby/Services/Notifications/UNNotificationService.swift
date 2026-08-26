import Foundation
import Observation
import UserNotifications

/// Production `NotificationService` backed by `UserNotifications` framework.
///
/// Implements `UNUserNotificationCenterDelegate` to present alerts while the app is in the foreground,
/// and routes lock-screen / banner interactive actions back to the `NarrationCoordinator`.
@Observable
final class UNNotificationService: NSObject, NotificationService {
  private(set) var isAuthorized: Bool = false
  var onAnswer: ((NotificationAnswer) -> Void)?

  static let categoryIdentifier = "APPROACH_PROMPT"
  static let playActionIdentifier = "PLAY_ACTION"
  static let dismissActionIdentifier = "DISMISS_ACTION"
  static let queueActionIdentifier = "QUEUE_ACTION"

  private let center: UNUserNotificationCenter
  private let settings: SettingsStore

  init(
    center: UNUserNotificationCenter = .current(),
    settings: SettingsStore = SettingsStore()
  ) {
    self.center = center
    self.settings = settings
    super.init()
    self.center.delegate = self
    self.syncLocalizedContent()
    Task { @MainActor in
      await self.refreshAuthorization()
    }
  }

  func requestAuthorization() async -> Bool {
    do {
      let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
      self.isAuthorized = granted
      return granted
    } catch {
      self.isAuthorized = false
      return false
    }
  }

  func refreshAuthorization() async {
    let settings = await center.notificationSettings()
    self.isAuthorized =
      settings.authorizationStatus == .authorized
      || settings.authorizationStatus == .provisional
  }

  func postPrompt(_ prompt: PendingPrompt) {
    let languageCode = settings.resolvedLanguageCode
    let content = UNMutableNotificationContent()
    content.title = ConsentStrings.notificationTitle(
      siteName: prompt.siteName,
      languageCode: languageCode
    )
    if let direction = prompt.directionPhrase, !direction.isEmpty {
      content.body = "\(direction) · \(prompt.storyTitle)"
    } else {
      content.body = prompt.storyTitle
    }
    content.sound = .default
    content.interruptionLevel = .timeSensitive
    content.categoryIdentifier = Self.categoryIdentifier
    content.userInfo = [
      "promptID": prompt.id.uuidString,
      "siteSlug": prompt.siteSlug,
      "storySlug": prompt.storySlug,
    ]

    let request = UNNotificationRequest(
      identifier: prompt.id.uuidString,
      content: content,
      trigger: nil
    )

    center.add(request) { error in
      if let error {
        print("Failed to schedule notification: \(error)")
      }
    }
  }

  func withdrawPrompt(id: UUID) {
    let idString = id.uuidString
    center.removePendingNotificationRequests(withIdentifiers: [idString])
    center.removeDeliveredNotifications(withIdentifiers: [idString])
  }

  func syncLocalizedContent() {
    registerCategories(languageCode: settings.resolvedLanguageCode)
  }

  // MARK: - Categories Setup

  private func registerCategories(languageCode: String) {
    // No `.foreground` — that forces unlock + opens the app. Consent must resolve from the
    // lock screen (Slice 13); Play / Queue / Dismiss all run in the background via `onAnswer`.
    let playAction = UNNotificationAction(
      identifier: Self.playActionIdentifier,
      title: ConsentStrings.playNowAction(languageCode: languageCode),
      options: []
    )

    let queueAction = UNNotificationAction(
      identifier: Self.queueActionIdentifier,
      title: ConsentStrings.addToQueueAction(languageCode: languageCode),
      options: []
    )

    let dismissAction = UNNotificationAction(
      identifier: Self.dismissActionIdentifier,
      title: ConsentStrings.dismissAction(languageCode: languageCode),
      options: [.destructive]
    )

    let category = UNNotificationCategory(
      identifier: Self.categoryIdentifier,
      actions: [playAction, queueAction, dismissAction],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )

    center.setNotificationCategories([category])
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension UNNotificationService: UNUserNotificationCenterDelegate {
  /// Presents notifications as banner + sound even when the app is in the foreground.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge, .list])
  }

  /// Handles user tapping notification actions or the banner itself.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    defer { completionHandler() }

    let userInfo = response.notification.request.content.userInfo
    guard let promptIDString = userInfo["promptID"] as? String,
      let promptID = UUID(uuidString: promptIDString)
    else { return }

    let actionIdentifier = response.actionIdentifier

    Task { @MainActor in
      switch actionIdentifier {
      case Self.playActionIdentifier:
        self.onAnswer?(.accept(promptID: promptID))
      case UNNotificationDefaultActionIdentifier:
        break
      case Self.dismissActionIdentifier, UNNotificationDismissActionIdentifier:
        self.onAnswer?(.dismiss(promptID: promptID))
      case Self.queueActionIdentifier:
        self.onAnswer?(.queue(promptID: promptID))
      default: break
      }
    }
  }
}
