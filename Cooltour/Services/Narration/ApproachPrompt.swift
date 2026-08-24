import Foundation

/// Builds the spoken approach line from a site name and an optional relative-direction phrase.
/// Pure and dependency-free — no Core Location import — in the `ProximityEvaluator` mould, so it's
/// trivially unit-testable and is the single seam Slice 12 plugs the real direction into.
///
/// A nil or empty direction omits the phrase entirely rather than guessing: per J3, the app says
/// nothing about direction when it isn't trustworthy.
enum ApproachPrompt {
  static func text(
    siteName: String,
    directionPhrase: String? = nil,
    languageCode: String = "en"
  ) -> String {
    ConsentStrings.approachPrompt(
      siteName: siteName,
      directionPhrase: directionPhrase,
      languageCode: languageCode
    )
  }
}
