import Foundation

/// One story firing at one place and time. A value type for now — Slice 8 turns walk history
/// into a SwiftData model; nothing in this slice needs it to survive a relaunch.
struct TriggerEvent: Identifiable, Sendable {
  let id = UUID()
  let date: Date
  let siteSlug: String
  let siteName: String
  let storySlug: String
  let storyTitle: String
  let distanceMeters: Double
  let horizontalAccuracyMeters: Double
}
