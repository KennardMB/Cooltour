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
    var recentEvents: [TriggerEvent] { get }
    /// Called on the main actor when a site fires. Wired to playback in `AppEnvironment`.
    var onTrigger: ((Site, Story) -> Void)? { get set }

    func start()
    func stop()
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
    private(set) var recentEvents: [TriggerEvent] = []
    var onTrigger: ((Site, Story) -> Void)?

    func start() { isListening = true }
    func stop() { isListening = false }

    /// Fires a site through the same path as the real engine, so previews and tests can
    /// exercise the trigger → playback wiring without GPS.
    func simulateTrigger(site: Site, distanceMeters: Double = 10) {
        guard let story = site.stories.first else { return }
        recentEvents.insert(
            TriggerEvent(
                date: .now,
                siteSlug: site.slug,
                siteName: site.name,
                storySlug: story.slug,
                storyTitle: story.title,
                distanceMeters: distanceMeters,
                horizontalAccuracyMeters: 8
            ),
            at: 0
        )
        onTrigger?(site, story)
    }
}
