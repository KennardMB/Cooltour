import Foundation

/// One story firing at one place and time. A flat value type emitted by the proximity engine,
/// keeping it decoupled from the SwiftData context and fully `Sendable`.
struct ProximityEvent: Identifiable, Codable, Sendable {
  var id: String { "\(siteSlug)@\(date.timeIntervalSince1970)" }
  let date: Date
  let siteSlug: String
  let siteName: String
  let storySlug: String
  let storyTitle: String
  let distanceMeters: Double
  let horizontalAccuracyMeters: Double
  let latitude: Double
  let longitude: Double
  let wasBackground: Bool
}
