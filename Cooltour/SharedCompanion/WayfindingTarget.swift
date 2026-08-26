import Foundation

/// Site the Watch should point at after playback starts. Phone arms this; Watch computes the arrow
/// locally (Slice 20–21). Flat and `Codable` so it rides `WatchSessionSnapshot`.
nonisolated struct WayfindingTarget: Equatable, Sendable, Codable {
  let siteSlug: String
  let siteName: String
  let latitude: Double
  let longitude: Double
  let triggerRadiusMeters: Double
}
