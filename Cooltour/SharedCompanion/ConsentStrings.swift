import Foundation

/// Localized copy for the consent gate (spoken prompt, notifications, Now status, Watch glance).
/// Uses an explicit language code so in-app language override works outside SwiftUI `Text`.
/// String Catalog keys are kept in sync for SwiftUI literals; programmatic strings live here
/// because `String(localized:locale:)` does not reliably resolve manual catalog keys at runtime.
enum ConsentStrings {
  static func approachPrompt(
    siteName: String,
    directionPhrase: String?,
    languageCode: String
  ) -> String {
    if let directionPhrase, !directionPhrase.isEmpty {
      let format = approachDirectionFormat(languageCode: languageCode)
      return String(format: format, siteName, directionPhrase)
    }
    let format = approachFormat(languageCode: languageCode)
    return String(format: format, siteName)
  }

  static func notificationTitle(siteName: String, languageCode: String) -> String {
    let format = languageCode == "id" ? "Mendekati %@" : "Approaching %@"
    return String(format: format, siteName)
  }

  /// Banner subtitle (the second line). Place-first: district, not story title.
  static func notificationBody(districtName: String, directionPhrase: String?) -> String {
    let district = districtName.trimmingCharacters(in: .whitespacesAndNewlines)
    if let directionPhrase, !directionPhrase.isEmpty {
      return district.isEmpty ? directionPhrase : "\(directionPhrase) · \(district)"
    }
    return district
  }

  static func statusApproaching(siteName: String, languageCode: String) -> String {
    let format = languageCode == "id" ? "Mendekati %@" : "Approaching %@"
    return String(format: format, siteName)
  }

  static func statusPrompting(languageCode: String) -> String {
    languageCode == "id"
      ? "Cerita di dekat — putar, antre, atau lewati?"
      : "Story nearby — play, queue, or pass?"
  }

  static func statusPlaying(title: String, languageCode: String) -> String {
    let format = languageCode == "id" ? "Memutar %@" : "Playing %@"
    return String(format: format, title)
  }

  static func statusPlayingUnknown(languageCode: String) -> String {
    languageCode == "id" ? "Memutar…" : "Playing…"
  }

  static func statusWalkingOff(languageCode: String) -> String {
    languageCode == "id" ? "Mode berjalan nonaktif" : "Walking mode is off"
  }

  static func statusListening(languageCode: String) -> String {
    languageCode == "id"
      ? "Mendengarkan cerita di sekitar"
      : "Listening for nearby stories"
  }

  static func statusStarting(languageCode: String) -> String {
    languageCode == "id" ? "Memulai…" : "Starting up…"
  }

  /// Slice 17 stub / Slice 18 unreachable phone — Watch is not a standalone brain.
  static func statusPhoneRequired(languageCode: String) -> String {
    languageCode == "id"
      ? "Gunakan iPhone yang terpasang"
      : "Requires the paired iPhone"
  }

  static func playNowAction(languageCode: String) -> String {
    languageCode == "id" ? "Putar sekarang" : "Play now"
  }

  static func addToQueueAction(languageCode: String) -> String {
    languageCode == "id" ? "Tambah ke antrean" : "Add to queue"
  }

  static func dismissAction(languageCode: String) -> String {
    languageCode == "id" ? "Lewati" : "Pass"
  }

  static func dismissWithCountdown(_ seconds: Int, languageCode: String) -> String {
    languageCode == "id" ? "Lewati (\(seconds))" : "Pass (\(seconds))"
  }

  static func storyPromptAccessibility(siteName: String, languageCode: String) -> String {
    let format = languageCode == "id" ? "Prompt cerita untuk %@" : "Story prompt for %@"
    return String(format: format, siteName)
  }

  private static func approachFormat(languageCode: String) -> String {
    languageCode == "id"
      ? "Anda mendekati %@. Tekan putar untuk mendengarkannya."
      : "You're approaching %@. Press play to hear it."
  }

  private static func approachDirectionFormat(languageCode: String) -> String {
    languageCode == "id"
      ? "Anda mendekati %@, %@. Tekan putar untuk mendengarkannya."
      : "You're approaching %@, %@. Press play to hear it."
  }
}
