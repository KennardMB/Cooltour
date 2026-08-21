import Foundation
import Observation

/// The answer routed from a user interacting with a local notification.
enum NotificationAnswer: Equatable, Sendable {
  case accept(promptID: UUID)
  case dismiss(promptID: UUID)
  case queue(promptID: UUID)
}

@MainActor
protocol NotificationService: AnyObject, Observable {
  var isAuthorized: Bool { get }
  var onAnswer: ((NotificationAnswer) -> Void)? { get set }

  func requestAuthorization() async -> Bool
  func refreshAuthorization() async
  func postPrompt(_ prompt: PendingPrompt)
  func withdrawPrompt(id: UUID)
  /// Re-register notification action labels when app language changes.
  func syncLocalizedContent()
}

@Observable
final class MockNotificationService: NotificationService {
  var isAuthorized = false
  var onAnswer: ((NotificationAnswer) -> Void)?

  private(set) var postedPrompts: [PendingPrompt] = []
  private(set) var withdrawnPromptIDs: [UUID] = []

  func requestAuthorization() async -> Bool {
    isAuthorized = true
    return true
  }

  func refreshAuthorization() async {}

  func postPrompt(_ prompt: PendingPrompt) {
    postedPrompts.append(prompt)
  }

  func withdrawPrompt(id: UUID) {
    withdrawnPromptIDs.append(id)
    postedPrompts.removeAll { $0.id == id }
  }

  func syncLocalizedContent() {}

  func simulateAnswer(_ answer: NotificationAnswer) {
    onAnswer?(answer)
  }
}
