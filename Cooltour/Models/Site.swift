import Foundation
import SwiftData

@Model
final class Site {
  /// Stable key authored in the content pack, e.g. "pura-maospahit".
  @Attribute(.unique) var slug: String
  var name: String
  var districtName: String
  var latitude: Double
  var longitude: Double
  var triggerRadiusMeters: Double
  var headingRequired: Bool
  var thumbnailAssetName: String?
  var imageSource: String?

  @Relationship(deleteRule: .cascade, inverse: \Story.site)
  var stories: [Story] = []

  init(
    slug: String,
    name: String,
    districtName: String,
    latitude: Double,
    longitude: Double,
    triggerRadiusMeters: Double,
    headingRequired: Bool,
    thumbnailAssetName: String? = nil,
    imageSource: String? = nil
  ) {
    self.slug = slug
    self.name = name
    self.districtName = districtName
    self.latitude = latitude
    self.longitude = longitude
    self.triggerRadiusMeters = triggerRadiusMeters
    self.headingRequired = headingRequired
    self.thumbnailAssetName = thumbnailAssetName
    self.imageSource = imageSource
  }
}
