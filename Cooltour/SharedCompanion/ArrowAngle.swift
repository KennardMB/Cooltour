import Foundation

/// Pure arrow math for the Watch wayfinding glance (Slice 21). No Core Location types in the API —
/// same mould as `ProximityEvaluator`.
enum ArrowAngle {
  /// Initial bearing from user → site, degrees clockwise from true north, in `[0, 360)`.
  static func bearingDegrees(
    fromLatitude: Double,
    fromLongitude: Double,
    toLatitude: Double,
    toLongitude: Double
  ) -> Double {
    let φ1 = fromLatitude * .pi / 180
    let φ2 = toLatitude * .pi / 180
    let Δλ = (toLongitude - fromLongitude) * .pi / 180
    let y = sin(Δλ) * cos(φ2)
    let x = cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(Δλ)
    let θ = atan2(y, x) * 180 / .pi
    return normalizeDegrees(θ)
  }

  /// Prefer GPS course while walking; else compass heading; else nil (hide the arrow).
  static func trustedHeadingDegrees(
    course: Double,
    courseAccuracy: Double,
    speedMetersPerSecond: Double,
    heading: Double,
    headingAccuracy: Double
  ) -> Double? {
    let courseOK =
      speedMetersPerSecond >= AppConfig.wayfindingMinWalkingSpeedMetersPerSecond
      && courseAccuracy >= 0
      && courseAccuracy <= AppConfig.wayfindingMaxCourseAccuracyDegrees
    if courseOK {
      return normalizeDegrees(course)
    }

    let headingOK =
      headingAccuracy >= 0
      && headingAccuracy <= AppConfig.wayfindingMaxHeadingAccuracyDegrees
    if headingOK {
      return normalizeDegrees(heading)
    }
    return nil
  }

  /// Arrow rotation in degrees (bearing − heading). Nil in → nil out.
  static func arrowRotationDegrees(bearing: Double?, heading: Double?) -> Double? {
    guard let bearing, let heading else { return nil }
    return normalizeDegrees(bearing - heading)
  }

  /// Full pipeline used by the Watch location loop.
  static func rotationDegrees(
    userLatitude: Double,
    userLongitude: Double,
    horizontalAccuracyMeters: Double,
    siteLatitude: Double,
    siteLongitude: Double,
    course: Double,
    courseAccuracy: Double,
    speedMetersPerSecond: Double,
    heading: Double,
    headingAccuracy: Double
  ) -> Double? {
    guard horizontalAccuracyMeters > 0,
      horizontalAccuracyMeters <= AppConfig.maxLocationAccuracyMeters
    else { return nil }

    let bearing = bearingDegrees(
      fromLatitude: userLatitude,
      fromLongitude: userLongitude,
      toLatitude: siteLatitude,
      toLongitude: siteLongitude
    )
    let headingDegrees = trustedHeadingDegrees(
      course: course,
      courseAccuracy: courseAccuracy,
      speedMetersPerSecond: speedMetersPerSecond,
      heading: heading,
      headingAccuracy: headingAccuracy
    )
    return arrowRotationDegrees(bearing: bearing, heading: headingDegrees)
  }

  /// Coarse relative hint for VoiceOver — not a second UI.
  static func relativeDirectionLabel(rotationDegrees: Double, languageCode: String) -> String {
    let r = normalizeDegrees(rotationDegrees)
    let bucket: String
    if r >= 315 || r < 45 {
      bucket = languageCode == "id" ? "di depan" : "ahead"
    } else if r < 135 {
      bucket = languageCode == "id" ? "di kanan" : "on your right"
    } else if r < 225 {
      bucket = languageCode == "id" ? "di belakang" : "behind you"
    } else {
      bucket = languageCode == "id" ? "di kiri" : "on your left"
    }
    return bucket
  }

  static func normalizeDegrees(_ degrees: Double) -> Double {
    var d = degrees.truncatingRemainder(dividingBy: 360)
    if d < 0 { d += 360 }
    return d
  }

  /// Haversine distance in meters (optional distance label on the glance).
  static func distanceMeters(
    fromLatitude: Double,
    fromLongitude: Double,
    toLatitude: Double,
    toLongitude: Double
  ) -> Double {
    let r = 6_371_000.0
    let φ1 = fromLatitude * .pi / 180
    let φ2 = toLatitude * .pi / 180
    let Δφ = (toLatitude - fromLatitude) * .pi / 180
    let Δλ = (toLongitude - fromLongitude) * .pi / 180
    let a =
      sin(Δφ / 2) * sin(Δφ / 2)
      + cos(φ1) * cos(φ2) * sin(Δλ / 2) * sin(Δλ / 2)
    return 2 * r * asin(min(1, sqrt(a)))
  }
}
