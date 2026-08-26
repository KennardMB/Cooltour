import CoreLocation
import Foundation

@MainActor
protocol ProximityEngine: AnyObject {
  var isListening: Bool { get }
  var authorizationStatus: CLAuthorizationStatus { get }
  /// Most recent location reading, trusted or not — the debug screen shows rejected fixes too.
  var lastFix: ProximityFix? { get }
  /// Every seeded site with its live distance, nearest first.
  var nearbySites: [NearbySite] { get }
  var onEventLogged: ((ProximityEvent) -> Void)? { get set }
  /// Called on the main actor when a site fires. Wired to playback in `AppEnvironment`.
  var onTrigger: ((Site, Story) -> Void)? { get set }

  func start()
  func stop()
}

extension ProximityEngine {
  /// Debug/preview affordance: fires a site through the same `onEventLogged` → `onTrigger` path
  /// as a real GPS entry, so Now / previews can exercise the consent gate without walking.
  func simulateTrigger(
    site: Site,
    distanceMeters: Double = 10,
    wasBackground: Bool = false
  ) {
    guard isListening else { return }
    guard let story = site.stories.first else { return }
    let event = ProximityEvent(
      date: .now,
      siteSlug: site.slug,
      siteName: site.name,
      storySlug: story.slug,
      storyTitle: story.title,
      distanceMeters: distanceMeters,
      horizontalAccuracyMeters: 8,
      latitude: site.latitude,
      longitude: site.longitude,
      wasBackground: wasBackground
    )
    onEventLogged?(event)
    onTrigger?(site, story)
  }
}

/// `nonisolated` because the project defaults every declaration to `@MainActor`, and an
/// isolated value type can't satisfy SwiftUI's generic (non-isolated) requirements.
nonisolated struct ProximityFix: Sendable {
  let latitude: Double
  let longitude: Double
  let horizontalAccuracyMeters: Double
  let date: Date
  /// False when accuracy is worse than `AppConfig.maxLocationAccuracyMeters`; such fixes trigger nothing.
  let isTrusted: Bool
}

/// Flat values rather than the `Site` model: the engine's published state stays `Sendable`
/// (and Watch-shareable), and SwiftData objects don't leak into view state.
nonisolated struct NearbySite: Identifiable, Sendable {
  /// The site's slug.
  let id: String
  let name: String
  let triggerRadiusMeters: Double
  let distanceMeters: Double
  /// False while the user is inside the site and hasn't left the re-arm ring yet.
  let isArmed: Bool

  var isInsideRadius: Bool { distanceMeters <= triggerRadiusMeters }
}

@Observable
final class MockProximityEngine: ProximityEngine {
  private(set) var isListening = false
  var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
  var lastFix: ProximityFix?
  var nearbySites: [NearbySite] = []
  var onEventLogged: ((ProximityEvent) -> Void)?
  var onTrigger: ((Site, Story) -> Void)?

  func start() { isListening = true }
  func stop() { isListening = false }
}

extension CLAuthorizationStatus {
  /// Shown in Settings and the proximity debug screen — one spelling of these states, not two.
  var displayName: String {
    switch self {
    case .notDetermined: "Not asked"
    case .restricted: "Restricted"
    case .denied: "Denied"
    case .authorizedAlways: "Always"
    case .authorizedWhenInUse: "When in use"
    @unknown default: "Unknown"
    }
  }
}
