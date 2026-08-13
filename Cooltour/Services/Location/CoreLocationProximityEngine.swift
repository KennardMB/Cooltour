import CoreLocation
import Foundation
import UIKit

/// Proximity detection in the foreground (Slice 3) and with the app backgrounded or the screen
/// locked (Slice 4).
///
/// Two Core Location mechanisms, doing two different jobs:
/// - `CLBackgroundActivitySession` keeps `CLLocationUpdate.liveUpdates()` flowing once the app
///   leaves the front. Without it the updates stop and nothing can trigger.
/// - `CLMonitor` registers a wide circular condition per site so the system can wake — or
///   relaunch — the app when the user walks into one. It's the wake source only; the trigger
///   decision stays with `ProximityEvaluator` and a precise fix.
@Observable
final class CoreLocationProximityEngine: ProximityEngine {
  private(set) var isListening = false
  private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
  private(set) var lastFix: ProximityFix?
  private(set) var nearbySites: [NearbySite] = []
  private(set) var recentEvents: [TriggerEvent]
  var onTrigger: ((Site, Story) -> Void)?

  /// Last geofence wake. Separates "never woken" from "woken but the fix wasn't good enough" —
  /// two failures that look identical from an empty trigger log.
  private(set) var lastWake: MonitorWake?

  struct MonitorWake: Sendable {
    let siteSlug: String
    let date: Date
  }

  /// Same name every launch: the monitored conditions are stored by the system under it, so a
  /// relaunched process picks up the existing set instead of registering duplicates.
  private static let monitorName = "CooltourSiteMonitor"

  private let content: any ContentStore
  /// Kept only for the authorization prompt and status; the fixes come from `CLLocationUpdate`.
  private let manager = CLLocationManager()
  private var evaluator = ProximityEvaluator()
  private var log: TriggerLog
  private var updates: Task<Void, Never>?
  private var monitorTask: Task<Void, Never>?
  private var backgroundSession: CLBackgroundActivitySession?
  private var hasRequestedAlways = false
  /// Site coordinates don't move; rebuilding a `CLLocation` per site per fix is pure waste.
  private var cachedLocations: [String: CLLocation] = [:]

  init(content: any ContentStore) {
    let log = TriggerLog()
    self.content = content
    self.log = log
    // Triggers from an earlier run are the point: they may have fired while the app was
    // backgrounded, or in a process the system has since killed.
    self.recentEvents = log.events
    self.authorizationStatus = manager.authorizationStatus
  }

  var isBackgroundTriggeringEnabled: Bool {
    UserDefaults.standard.bool(forKey: AppConfig.backgroundTriggeringKey)
  }

  func start() {
    guard !isListening else { return }
    isListening = true

    let backgroundEnabled = isBackgroundTriggeringEnabled
    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
    authorizationStatus = manager.authorizationStatus

    if backgroundEnabled {
      backgroundSession = CLBackgroundActivitySession()
    }
    // Runs either way: with the feature off this is what removes conditions registered
    // while it was on, so a disabled app can't still be woken by a geofence.
    monitorTask = Task { [weak self] in
      await self?.syncMonitor(enabled: backgroundEnabled)
    }

    // `liveUpdates` is an async sequence, so there's no delegate to hop off the main
    // actor and back — the loop already runs where the observable state lives.
    updates = Task { [weak self] in
      do {
        for try await update in CLLocationUpdate.liveUpdates() {
          guard let self else { return }
          self.refreshAuthorization()
          guard let location = update.location else { continue }
          self.handle(location)
        }
      } catch {}

      // The stream also *ends* without throwing — when authorization is revoked mid-walk,
      // or the background session goes away. Tearing down here is what stops `isListening`
      // from claiming a feed that already died; a screen that says "listening" while
      // nothing arrives is worse than one that admits it stopped.
      //
      // ponytail: no retry. Add a bounded restart if a real walk shows the stream dropping
      // on its own — a retry loop against a permanently denied permission is worse.
      self?.stop()
    }
  }

  func stop() {
    updates?.cancel()
    updates = nil
    monitorTask?.cancel()
    monitorTask = nil
    // Ends the background grant immediately rather than at the next launch.
    backgroundSession?.invalidate()
    backgroundSession = nil
    isListening = false
    cachedLocations.removeAll()
  }

  func clearLog() {
    log.clear()
    recentEvents = log.events
  }

  /// "Always" can only be asked for once When-In-Use is granted, so the escalation rides on the
  /// first fix after the user accepted the first prompt instead of needing a delegate.
  private func refreshAuthorization() {
    authorizationStatus = manager.authorizationStatus
    guard isBackgroundTriggeringEnabled, !hasRequestedAlways,
      authorizationStatus == .authorizedWhenInUse
    else { return }
    hasRequestedAlways = true
    manager.requestAlwaysAuthorization()
  }

  /// Reconciles the monitored set with the setting. Adding a condition that's already recorded
  /// would re-register it on every launch, so existing identifiers are left alone.
  private func syncMonitor(enabled: Bool) async {
    let monitor = await CLMonitor(Self.monitorName)

    guard enabled else {
      for identifier in await monitor.identifiers {
        await monitor.remove(identifier)
      }
      return
    }

    // Conditions outlive the process, so a content pack that drops or renames a site would
    // otherwise keep waking the app for a place that has no story left to play.
    let currentSlugs = Set(content.allSites().map(\.slug))
    for identifier in await monitor.identifiers
    where !currentSlugs.contains(identifier) {
      await monitor.remove(identifier)
    }

    for site in content.allSites() {
      guard await monitor.record(for: site.slug) == nil else { continue }
      await monitor.add(
        CLMonitor.CircularGeographicCondition(
          center: CLLocationCoordinate2D(
            latitude: site.latitude,
            longitude: site.longitude
          ),
          radius: max(
            site.triggerRadiusMeters,
            AppConfig.monitorWakeRadiusMeters
          )
        ),
        identifier: site.slug
      )
    }

    // Draining the stream is what keeps the app subscribed — including for the launch event
    // when Core Location relaunches a terminated app. The event fires no story itself: a
    // geofence this wide can't tell the user is close enough and carries no accuracy, so it
    // only records that the wake happened and leaves the decision to the live fix.
    //
    // ponytail: updates run continuously while listening. Gate them on monitor state
    // (start on satisfied, stop on unsatisfied) if a full walk measurably hurts battery.
    do {
      for try await event in await monitor.events where event.state == .satisfied {
        lastWake = MonitorWake(siteSlug: event.identifier, date: event.date)
      }
    } catch {
      // A later stream failure doesn't unmake a wake that already happened — keep the
      // evidence, it's the only thing that separates "never woken" from "woken, no fix".
    }
  }

  private func handle(_ location: CLLocation) {
    let sites = content.allSites()
    let distances = sites.map { site -> (site: Site, meters: Double) in
      let siteLocation: CLLocation
      if let cached = cachedLocations[site.slug] {
        siteLocation = cached
      } else {
        siteLocation = CLLocation(
          latitude: site.latitude,
          longitude: site.longitude
        )
        cachedLocations[site.slug] = siteLocation
      }
      return (site: site, meters: location.distance(from: siteLocation))
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
      isTrusted: evaluator.accepts(
        horizontalAccuracyMeters: location.horizontalAccuracy
      )
    )
    nearbySites =
      distances
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

    let wasBackground = UIApplication.shared.applicationState != .active

    for slug in fired {
      guard let entry = distances.first(where: { $0.site.slug == slug }),
        let story = entry.site.stories.first
      else { continue }

      log.insert(
        TriggerEvent(
          date: .now,
          siteSlug: entry.site.slug,
          siteName: entry.site.name,
          storySlug: story.slug,
          storyTitle: story.title,
          distanceMeters: entry.meters,
          horizontalAccuracyMeters: location.horizontalAccuracy,
          wasBackground: wasBackground
        )
      )
      recentEvents = log.events

      // ponytail: overlapping radii (Jagatnatha and Museum Bali are ~30m apart) log every
      // entry but only hand the nearest one to playback — two stories at once is worse than
      // one missed. Queueing belongs to the audio service in Slice 2.
      if slug == fired.first {
        onTrigger?(entry.site, story)
      }
    }
  }
}
