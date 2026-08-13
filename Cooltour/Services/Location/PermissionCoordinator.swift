import CoreLocation
import Foundation
import Observation

@Observable
@MainActor
final class PermissionCoordinator: NSObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()

  var authorizationStatus: CLAuthorizationStatus

  override init() {
    self.authorizationStatus = locationManager.authorizationStatus
    super.init()
    self.locationManager.delegate = self
  }

  func requestLocationPermission() {
    // This is what actually triggers the system popup
    locationManager.requestWhenInUseAuthorization()
  }

  nonisolated func locationManagerDidChangeAuthorization(
    _ manager: CLLocationManager
  ) {
    let newStatus = manager.authorizationStatus
    Task { @MainActor in
      self.authorizationStatus = newStatus
    }
  }
}
