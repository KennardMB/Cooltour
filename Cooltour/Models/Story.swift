import Foundation
import SwiftData

@Model
final class Story {
  @Attribute(.unique) var slug: String
  var title: String
  /// English audio asset (primary until language preference ships).
  var audioAssetName: String
  /// Indonesian audio asset when the pack ships both languages.
  var audioAssetNameIndonesian: String?
  /// English transcript (primary for Now-card fallback until language preference ships).
  var transcript: String
  /// Indonesian transcript when the content pack ships both languages.
  var transcriptIndonesian: String?
  /// English spoken duration (primary until language preference ships).
  var durationSeconds: Double
  /// Indonesian spoken duration when the pack ships both languages.
  var durationSecondsIndonesian: Double?
  var narratorNote: String?
  var timeOfDayTag: String?

  var site: Site?

  init(
    slug: String,
    title: String,
    audioAssetName: String,
    audioAssetNameIndonesian: String? = nil,
    transcript: String,
    transcriptIndonesian: String? = nil,
    durationSeconds: Double,
    durationSecondsIndonesian: Double? = nil,
    narratorNote: String? = nil,
    timeOfDayTag: String? = nil
  ) {
    self.slug = slug
    self.title = title
    self.audioAssetName = audioAssetName
    self.audioAssetNameIndonesian = audioAssetNameIndonesian
    self.transcript = transcript
    self.transcriptIndonesian = transcriptIndonesian
    self.durationSeconds = durationSeconds
    self.durationSecondsIndonesian = durationSecondsIndonesian
    self.narratorNote = narratorNote
    self.timeOfDayTag = timeOfDayTag
  }
}
