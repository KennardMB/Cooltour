import Foundation

/// In-app UI language. `system` follows the iPhone language; `english` / `indonesian` override it.
enum AppLanguagePreference: String, CaseIterable, Identifiable {
  case system
  case english = "en"
  case indonesian = "id"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .system:
      String(localized: "System")
    case .english:
      String(localized: "English")
    case .indonesian:
      String(localized: "Bahasa Indonesia")
    }
  }

  /// Locale applied to SwiftUI when this preference is active.
  var locale: Locale {
    switch self {
    case .system:
      .autoupdatingCurrent
    case .english:
      Locale(identifier: "en")
    case .indonesian:
      Locale(identifier: "id")
    }
  }
}
