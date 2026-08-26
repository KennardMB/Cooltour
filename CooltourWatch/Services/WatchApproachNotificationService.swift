import Foundation
import UserNotifications

/// Watch-side local notifications for approach prompts (Slice 24).
/// Tap opens Cooltour Watch onto the consent gate; no interactive actions on the banner.
@MainActor
protocol WatchApproachNotifying: AnyObject {
  func requestAuthorizationIfNeeded()
  func postApproach(siteName: String, promptID: UUID, languageCode: String)
  func withdrawPrompt(id: UUID)
}

@MainActor
final class WatchApproachNotificationService: NSObject, WatchApproachNotifying {
  private let center: UNUserNotificationCenter
  private var didRequestAuthorization = false

  init(center: UNUserNotificationCenter = .current()) {
    self.center = center
    super.init()
    center.delegate = self
  }

  func requestAuthorizationIfNeeded() {
    Task {
      let settings = await center.notificationSettings()
      if settings.authorizationStatus == .notDetermined {
        didRequestAuthorization = true
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
      } else if !didRequestAuthorization {
        // Already decided — still mark so we don't spam; posts check status each time.
        didRequestAuthorization = true
      }
    }
  }

  func postApproach(siteName: String, promptID: UUID, languageCode: String) {
    Task {
      var settings = await center.notificationSettings()
      if settings.authorizationStatus == .notDetermined {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
        settings = await center.notificationSettings()
      }
      let allowed =
        settings.authorizationStatus == .authorized
        || settings.authorizationStatus == .provisional
      guard allowed else { return }

      let content = UNMutableNotificationContent()
      content.title = ConsentStrings.notificationTitle(
        siteName: siteName,
        languageCode: languageCode
      )
      content.body = ConsentStrings.statusPrompting(languageCode: languageCode)
      content.sound = .default
      content.userInfo = [
        "promptID": promptID.uuidString,
        "siteSlug": siteName,
      ]

      let request = UNNotificationRequest(
        identifier: promptID.uuidString,
        content: content,
        trigger: nil
      )
      try? await center.add(request)
    }
  }

  func withdrawPrompt(id: UUID) {
    let idString = id.uuidString
    center.removePendingNotificationRequests(withIdentifiers: [idString])
    center.removeDeliveredNotifications(withIdentifiers: [idString])
  }
}

extension WatchApproachNotificationService: UNUserNotificationCenterDelegate {
  /// Always present sound (and banner). Empty options previously silenced the wrist buzz when
  /// WatchConnectivity briefly woke Cooltour Watch to deliver `transferUserInfo` — that wake
  /// counts as "foreground" for `willPresent`, so the approach alert never showed.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .list])
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}

@MainActor
final class MockWatchApproachNotifier: WatchApproachNotifying {
  private(set) var postedPromptIDs: [UUID] = []
  private(set) var withdrawnPromptIDs: [UUID] = []
  private(set) var authorizationRequested = false

  func requestAuthorizationIfNeeded() {
    authorizationRequested = true
  }

  func postApproach(siteName: String, promptID: UUID, languageCode: String) {
    postedPromptIDs.append(promptID)
  }

  func withdrawPrompt(id: UUID) {
    withdrawnPromptIDs.append(id)
  }
}
