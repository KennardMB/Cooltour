import Foundation

/// Spoken story language — independent of app UI language.
enum AudioLanguagePreference: String, CaseIterable, Identifiable {
  case english = "en"
  case indonesian = "id"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .english:
      String(localized: "English")
    case .indonesian:
      String(localized: "Bahasa Indonesia")
    }
  }
}
