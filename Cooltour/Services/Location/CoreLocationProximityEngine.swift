import CoreLocation
import Foundation

/// Foreground proximity detection (Slice 3). Background region monitoring via `CLMonitor`
/// arrives in Slice 4 — this engine only runs while the app is in front.
@Observable
final class CoreLocationProximityEngine: ProximityEngine {
    private(set) var isListening = false
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var lastFix: ProximityFix?
    private(set) var nearbySites: [NearbySite] = []
    private(set) var recentEvents: [TriggerEvent] = []
    var onTrigger: ((Site, Story) -> Void)?

    private let content: any ContentStore
    /// Kept only for the authorization prompt and status; the fixes come from `CLLocationUpdate`.
    private let manager = CLLocationManager()
    private var evaluator = ProximityEvaluator()
    private var updates: Task<Void, Never>?

    init(content: any ContentStore) {
        self.content = content
        self.authorizationStatus = manager.authorizationStatus
    }

    func start() {
        guard !isListening else { return }
        isListening = true

        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        authorizationStatus = manager.authorizationStatus

        // `liveUpdates` is an async sequence, so there's no delegate to hop off the main
        // actor and back — the loop already runs where the observable state lives.
        updates = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard let self else { return }
                    self.authorizationStatus = self.manager.authorizationStatus
                    guard let location = update.location else { continue }
                    self.handle(location)
                }
            } catch {
                self?.stop()
            }
        }
    }

    func stop() {
        updates?.cancel()
        updates = nil
        isListening = false
    }

    private func handle(_ location: CLLocation) {
        let sites = content.allSites()
        let distances = sites.map { site in
            (site: site, meters: location.distance(
                from: CLLocation(latitude: site.latitude, longitude: site.longitude)
            ))
        }

        let fired = evaluator.evaluate(
            candidates: distances.map {
                .init(
                    slug: $0.site.slug,
                    distanceMeters: $0.meters,
                    triggerRadiusMeters: $0.site.triggerRadiusMeters
                )
            },
            horizontalAccuracyMeters: location.horizontalAccuracy
        )

        lastFix = ProximityFix(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            date: location.timestamp,
            isTrusted: evaluator.accepts(horizontalAccuracyMeters: location.horizontalAccuracy)
        )
        nearbySites = distances
            .sorted { $0.meters < $1.meters }
            .map {
                NearbySite(
                    id: $0.site.slug,
                    name: $0.site.name,
                    triggerRadiusMeters: $0.site.triggerRadiusMeters,
                    distanceMeters: $0.meters,
                    isArmed: evaluator.isArmed($0.site.slug)
                )
            }

        for slug in fired {
            guard let entry = distances.first(where: { $0.site.slug == slug }),
                  let story = entry.site.stories.first else { continue }

            recentEvents.insert(
                TriggerEvent(
                    date: .now,
                    siteSlug: entry.site.slug,
                    siteName: entry.site.name,
                    storySlug: story.slug,
                    storyTitle: story.title,
                    distanceMeters: entry.meters,
                    horizontalAccuracyMeters: location.horizontalAccuracy
                ),
                at: 0
            )

            // ponytail: overlapping radii (Jagatnatha and Museum Bali are ~30m apart) log every
            // entry but only hand the nearest one to playback — two stories at once is worse than
            // one missed. Queueing belongs to the audio service in Slice 2.
            if slug == fired.first {
                onTrigger?(entry.site, story)
            }
        }
    }
}
