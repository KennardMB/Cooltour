import Foundation

/// Minimal phone→Watch wake dictionary (property-list strings only).
/// Used with `transferUserInfo` / `sendMessage` so watchOS can deliver while Cooltour Watch
/// is suspended — full `WatchSessionSnapshot` Data blobs are less reliable for that path.
enum WatchWakePayload {
  static let typeKey = "wakeType"
  static let typeApproach = "approach"
  static let typeClear = "clear"
  static let promptIDKey = "promptID"
  static let siteNameKey = "siteName"
  static let languageCodeKey = "languageCode"

  static func approach(
    promptID: UUID,
    siteName: String,
    languageCode: String
  ) -> [String: String] {
    [
      typeKey: typeApproach,
      promptIDKey: promptID.uuidString,
      siteNameKey: siteName,
      languageCodeKey: languageCode,
    ]
  }

  static func clear(promptID: UUID?) -> [String: String] {
    var payload = [typeKey: typeClear]
    if let promptID {
      payload[promptIDKey] = promptID.uuidString
    }
    return payload
  }

  static func parseApproach(_ info: [String: String]) -> (promptID: UUID, siteName: String, languageCode: String)? {
    guard info[typeKey] == typeApproach,
      let idString = info[promptIDKey],
      let promptID = UUID(uuidString: idString),
      let siteName = info[siteNameKey],
      let languageCode = info[languageCodeKey]
    else { return nil }
    return (promptID, siteName, languageCode)
  }

  static func parseClear(_ info: [String: String]) -> UUID? {
    guard info[typeKey] == typeClear else { return nil }
    guard let idString = info[promptIDKey] else { return nil }
    return UUID(uuidString: idString)
  }
}
