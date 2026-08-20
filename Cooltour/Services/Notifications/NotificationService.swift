import Foundation
import UserNotifications

protocol NotificationService: AnyObject {
  var isAuthorized: Bool { get }
  var onPackDownloadRequested: ((String) -> Void)? { get set }
  var onPackNotNow: ((String) -> Void)? { get set }
  func postPackAvailable(_ pack: RemotePack)
}

@Observable
final class MockNotificationService: NotificationService {
  var isAuthorized = false
  var postedPacks: [RemotePack] = []
  var onPackDownloadRequested: ((String) -> Void)?
  var onPackNotNow: ((String) -> Void)?

  func postPackAvailable(_ pack: RemotePack) {
    postedPacks.append(pack)
  }
}

/// Local notifications for undownloaded city packs. Separate category from story consent.
@Observable
final class LocalNotificationService: NSObject, NotificationService, UNUserNotificationCenterDelegate {
  private(set) var isAuthorized = false
  var onPackDownloadRequested: ((String) -> Void)?
  var onPackNotNow: ((String) -> Void)?

  private nonisolated static let categoryID = "PACK_AVAILABLE"
  private nonisolated static let downloadActionID = "PACK_DOWNLOAD"
  private nonisolated static let notNowActionID = "PACK_NOT_NOW"
  private nonisolated static let packIDKey = "packID"

  override init() {
    super.init()
    let download = UNNotificationAction(
      identifier: Self.downloadActionID,
      title: "Download",
      options: []
    )
    let notNow = UNNotificationAction(
      identifier: Self.notNowActionID,
      title: "Not now",
      options: .destructive
    )
    let category = UNNotificationCategory(
      identifier: Self.categoryID,
      actions: [download, notNow],
      intentIdentifiers: []
    )
    let center = UNUserNotificationCenter.current()
    center.setNotificationCategories([category])
    center.delegate = self
    center.getNotificationSettings { [weak self] settings in
      let authorized = settings.authorizationStatus == .authorized
      Task { @MainActor in
        self?.isAuthorized = authorized
      }
    }
  }

  func postPackAvailable(_ pack: RemotePack) {
    Task {
      let center = UNUserNotificationCenter.current()
      let granted = try? await center.requestAuthorization(options: [.alert, .sound])
      await MainActor.run { isAuthorized = granted == true }
      guard granted == true else { return }

      let megabytes = Double(pack.sizeBytes) / 1_000_000
      let sizeText = String(format: "%.1f MB", megabytes)
      let content = UNMutableNotificationContent()
      content.title = "\(pack.name) stories available"
      content.body = "Download (\(sizeText)) to hear stories here."
      content.categoryIdentifier = Self.categoryID
      content.userInfo = [Self.packIDKey: pack.id]
      content.sound = .default
      let request = UNNotificationRequest(
        identifier: "pack-\(pack.id)",
        content: content,
        trigger: nil
      )
      try? await center.add(request)
    }
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    let packID =
      response.notification.request.content.userInfo[Self.packIDKey] as? String
    guard let packID else { return }
    let action = response.actionIdentifier
    await MainActor.run {
      switch action {
      case Self.downloadActionID, UNNotificationDefaultActionIdentifier:
        onPackDownloadRequested?(packID)
      case Self.notNowActionID:
        onPackNotNow?(packID)
      default:
        break
      }
    }
  }
}
