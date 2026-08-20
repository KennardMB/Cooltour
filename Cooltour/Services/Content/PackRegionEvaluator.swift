import CoreLocation
import Foundation

/// City-circle entry for undownloaded packs. Not a story trigger — crossing the pack radius
/// asks her to download, then disarms until she leaves the re-arm ring.
struct PackRegionEvaluator {
  private var known: Set<String> = []
  private var armed: Set<String> = []

  mutating func evaluate(packs: [RemotePack], at location: CLLocation) -> [RemotePack] {
    var fired: [RemotePack] = []
    for pack in packs {
      if !known.contains(pack.id) {
        known.insert(pack.id)
        armed.insert(pack.id)
      }
      let center = CLLocation(latitude: pack.latitude, longitude: pack.longitude)
      let distance = location.distance(from: center)
      if distance <= pack.radiusMeters {
        if armed.contains(pack.id) {
          armed.remove(pack.id)
          fired.append(pack)
        }
      } else if distance > pack.radiusMeters * AppConfig.reArmRadiusMultiplier {
        armed.insert(pack.id)
      }
    }
    return fired
  }
}
