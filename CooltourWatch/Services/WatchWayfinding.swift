import CoreLocation
import Foundation
import Observation

/// Watch Core Location loop — runs **only** while a `wayfindingTarget` is armed (Slice 21).
@MainActor
@Observable
final class WatchWayfinding: NSObject, CLLocationManagerDelegate {
  private(set) var arrowRotationDegrees: Double?
  private(set) var distanceMeters: Double?
  private(set) var authorizationDenied = false

  private let manager = CLLocationManager()
  private var target: WayfindingTarget?
  private var lastHeading: CLHeadingProxy?

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.headingFilter = 2
  }

  func updateTarget(_ target: WayfindingTarget?) {
    self.target = target
    if target == nil {
      stop()
      arrowRotationDegrees = nil
      distanceMeters = nil
      return
    }
    requestAndStartIfNeeded()
  }

  private func requestAndStartIfNeeded() {
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .denied, .restricted:
      authorizationDenied = true
      arrowRotationDegrees = nil
    case .authorizedWhenInUse, .authorizedAlways:
      authorizationDenied = false
      manager.startUpdatingLocation()
      manager.startUpdatingHeading()
    @unknown default:
      arrowRotationDegrees = nil
    }
  }

  private func stop() {
    manager.stopUpdatingLocation()
    manager.stopUpdatingHeading()
  }

  private func recompute(location: CLLocation) {
    guard let target else {
      arrowRotationDegrees = nil
      distanceMeters = nil
      return
    }

    let course = location.course
    let courseAccuracy = location.courseAccuracy
    let speed = max(0, location.speed)
    let heading = lastHeading?.trueHeading ?? lastHeading?.magneticHeading ?? -1
    let headingAccuracy = lastHeading?.headingAccuracy ?? -1

    arrowRotationDegrees = ArrowAngle.rotationDegrees(
      userLatitude: location.coordinate.latitude,
      userLongitude: location.coordinate.longitude,
      horizontalAccuracyMeters: location.horizontalAccuracy,
      siteLatitude: target.latitude,
      siteLongitude: target.longitude,
      course: course,
      courseAccuracy: courseAccuracy,
      speedMetersPerSecond: speed,
      heading: heading,
      headingAccuracy: headingAccuracy
    )

    if location.horizontalAccuracy > 0,
      location.horizontalAccuracy <= AppConfig.maxLocationAccuracyMeters
    {
      distanceMeters = ArrowAngle.distanceMeters(
        fromLatitude: location.coordinate.latitude,
        fromLongitude: location.coordinate.longitude,
        toLatitude: target.latitude,
        toLongitude: target.longitude
      )
    } else {
      distanceMeters = nil
    }
  }

  // MARK: - CLLocationManagerDelegate

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      self.requestAndStartIfNeeded()
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else { return }
    Task { @MainActor in
      self.recompute(location: location)
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let trueHeading = newHeading.trueHeading
    let magneticHeading = newHeading.magneticHeading
    let accuracy = newHeading.headingAccuracy
    Task { @MainActor in
      let heading = CLHeadingProxy(
        trueHeading: trueHeading,
        magneticHeading: magneticHeading,
        headingAccuracy: accuracy
      )
      self.lastHeading = heading
      if let location = self.manager.location {
        self.recompute(location: location)
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Task { @MainActor in
      // Silence on failure — keep site name, hide arrow.
      self.arrowRotationDegrees = nil
    }
  }
}

/// `CLHeading` isn't comfortably Sendable across actors — keep the fields we need.
private struct CLHeadingProxy {
  let trueHeading: CLLocationDirection
  let magneticHeading: CLLocationDirection
  let headingAccuracy: CLLocationDirection
}
