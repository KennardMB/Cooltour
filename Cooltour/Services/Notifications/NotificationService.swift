import Foundation

protocol NotificationService: AnyObject {
  var isAuthorized: Bool { get }
}

@Observable
final class MockNotificationService: NotificationService {
  var isAuthorized = false
}
