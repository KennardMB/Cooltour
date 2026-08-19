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
  /// Raw value of `PromptOutcome`. A three-way (plus `pending`) outcome replaces the old
  /// `wasAutoPlayed` Bool now that every story is consented to (Slice 11). Stored as a String so
  /// SwiftData persists it without a custom transformer.
  /// Default is required for lightweight migration: older stores have rows with no `outcome`, and
  /// Core Data refuses to migrate a mandatory attribute that has nothing to fill it with.
  var outcome: String = PromptOutcome.pending.rawValue
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
    outcome: PromptOutcome,
    userLatitude: Double,
    userLongitude: Double,
    wasBackground: Bool
  ) {
    self.siteSlug = siteSlug
    self.siteName = siteName
    self.storySlug = storySlug
    self.storyTitle = storyTitle
    self.firedAt = firedAt
    self.outcome = outcome.rawValue
    self.userLatitude = userLatitude
    self.userLongitude = userLongitude
    self.wasBackground = wasBackground
  }
}
