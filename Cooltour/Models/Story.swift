import Foundation
import SwiftData

@Model
final class Story {
  @Attribute(.unique) var slug: String
  var title: String
  var audioAssetName: String
  /// English transcript (primary for Now-card fallback until language preference ships).
  var transcript: String
  /// Indonesian transcript when the content pack ships both languages.
  var transcriptIndonesian: String?
  var durationSeconds: Double
  var narratorNote: String?
  var timeOfDayTag: String?

  var site: Site?

  init(
    slug: String,
    title: String,
    audioAssetName: String,
    transcript: String,
    transcriptIndonesian: String? = nil,
    durationSeconds: Double,
    narratorNote: String? = nil,
    timeOfDayTag: String? = nil
  ) {
    self.slug = slug
    self.title = title
    self.audioAssetName = audioAssetName
    self.transcript = transcript
    self.transcriptIndonesian = transcriptIndonesian
    self.durationSeconds = durationSeconds
    self.narratorNote = narratorNote
    self.timeOfDayTag = timeOfDayTag
  }
}
