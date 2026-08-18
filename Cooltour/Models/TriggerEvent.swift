import Foundation
import SwiftData

@Model
final class TriggerEvent {
  var id: UUID = UUID()
  var siteSlug: String
  var siteName: String
  var storySlug: String
  var storyTitle: String
  var firedAt: Date
  var wasAutoPlayed: Bool
  var userLatitude: Double
  var userLongitude: Double
  var wasBackground: Bool
  
  var walk: Walk?

  init(
    siteSlug: String,
    siteName: String,
    storySlug: String,
    storyTitle: String,
    firedAt: Date = .now,
    wasAutoPlayed: Bool,
    userLatitude: Double,
    userLongitude: Double,
    wasBackground: Bool
  ) {
    self.siteSlug = siteSlug
    self.siteName = siteName
    self.storySlug = storySlug
    self.storyTitle = storyTitle
    self.firedAt = firedAt
    self.wasAutoPlayed = wasAutoPlayed
    self.userLatitude = userLatitude
    self.userLongitude = userLongitude
    self.wasBackground = wasBackground
  }
}
