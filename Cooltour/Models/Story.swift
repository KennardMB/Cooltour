import Foundation
import SwiftData

@Model
final class Story {
  @Attribute(.unique) var slug: String
  var title: String
  var audioAssetName: String
  var transcript: String
  var durationSeconds: Double
  var narratorNote: String?
  var timeOfDayTag: String?

  var site: Site?

  init(
    slug: String,
    title: String,
    audioAssetName: String,
    transcript: String,
    durationSeconds: Double,
    narratorNote: String? = nil,
    timeOfDayTag: String? = nil
  ) {
    self.slug = slug
    self.title = title
    self.audioAssetName = audioAssetName
    self.transcript = transcript
    self.durationSeconds = durationSeconds
    self.narratorNote = narratorNote
    self.timeOfDayTag = timeOfDayTag
  }
}
