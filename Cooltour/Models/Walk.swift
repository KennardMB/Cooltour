import Foundation
import SwiftData

@Model
final class Walk {
  var id: UUID = UUID()
  var startedAt: Date
  var endedAt: Date?

  @Relationship(deleteRule: .cascade, inverse: \TriggerEvent.walk)
  var triggerEvents: [TriggerEvent] = []

  init(startedAt: Date = .now) {
    self.startedAt = startedAt
  }
}
