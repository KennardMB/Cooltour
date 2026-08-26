import Foundation
import SwiftData

@Model
final class Walk {
  var id: UUID = UUID()
  var startedAt: Date
  var endedAt: Date?
  /// User-edited display title; nil/empty means fall back to the generated first–last title.
  var customTitle: String?
  /// Persisted `CulturalColorTheme.rawValue`; nil means the default blue theme.
  var themeRawValue: String?

  @Relationship(deleteRule: .cascade, inverse: \TriggerEvent.walk)
  var triggerEvents: [TriggerEvent] = []

  init(startedAt: Date = .now) {
    self.startedAt = startedAt
  }
}
