import Foundation
import UserNotifications

/// Watch-side local notifications for approach prompts (Slice 24).
/// Tap opens Cooltour Watch onto the consent gate; no interactive actions on the banner.
@MainActor
protocol WatchApproachNotifying: AnyObject {
  func requestAuthorizationIfNeeded()
  func postPrompt(_ prompt: PendingPrompt, languageCode: String)
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
    guard !didRequestAuthorization else { return }
    didRequestAuthorization = true
    Task {
      _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }
  }

  func postPrompt(_ prompt: PendingPrompt, languageCode: String) {
    let content = UNMutableNotificationContent()
    content.title = ConsentStrings.notificationTitle(
      siteName: prompt.siteName,
      languageCode: languageCode
    )
    // Site name is already the title; body nudges the tap without dumping the spoken prompt.
    content.body = ConsentStrings.statusPrompting(languageCode: languageCode)
    // Default sound so the wrist buzzes when the Watch app is not open.
    content.sound = .default
    content.userInfo = [
      "promptID": prompt.id.uuidString,
      "siteSlug": prompt.siteSlug,
    ]

    let request = UNNotificationRequest(
      identifier: prompt.id.uuidString,
      content: content,
      trigger: nil
    )
    center.add(request) { _ in }
  }

  func withdrawPrompt(id: UUID) {
    let idString = id.uuidString
    center.removePendingNotificationRequests(withIdentifiers: [idString])
    center.removeDeliveredNotifications(withIdentifiers: [idString])
  }
}

extension WatchApproachNotificationService: UNUserNotificationCenterDelegate {
  /// App already open on the consent card — don't stack a banner on top.
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([])
  }

  /// Default tap opens the Watch app; consent answers stay on the glance (same promptID).
  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}

/// Preview / test double — records posts and withdrawals without UserNotifications.
@MainActor
final class MockWatchApproachNotifier: WatchApproachNotifying {
  private(set) var postedPromptIDs: [UUID] = []
  private(set) var withdrawnPromptIDs: [UUID] = []
  private(set) var authorizationRequested = false

  func requestAuthorizationIfNeeded() {
    authorizationRequested = true
  }

  func postPrompt(_ prompt: PendingPrompt, languageCode: String) {
    postedPromptIDs.append(prompt.id)
  }

  func withdrawPrompt(id: UUID) {
    withdrawnPromptIDs.append(id)
  }
}
