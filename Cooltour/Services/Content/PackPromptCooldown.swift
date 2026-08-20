import Foundation

/// Suppresses pack-available prompts: ignore for 24h, or Not now until the walk ends.
struct PackPromptCooldown {
  private var notNowPackIDs: Set<String> = []
  private var ignoredUntil: [String: Date] = [:]

  mutating func recordIgnore(packID: String, now: Date = .now) {
    ignoredUntil[packID] = now.addingTimeInterval(24 * 60 * 60)
  }

  mutating func recordNotNow(packID: String) {
    notNowPackIDs.insert(packID)
  }

  mutating func endWalk() {
    notNowPackIDs.removeAll()
  }

  func shouldPrompt(packID: String, now: Date = .now) -> Bool {
    if notNowPackIDs.contains(packID) { return false }
    if let until = ignoredUntil[packID], now < until { return false }
    return true
  }
}
