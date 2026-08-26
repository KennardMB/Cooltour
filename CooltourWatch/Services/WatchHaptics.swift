import WatchKit

/// Distinct wrist patterns — A on approach/consent, B on play-start (PRD §8.3).
enum WatchHaptics {
  /// Approach / consent prompt appeared.
  static func playApproach() {
    // Custom-ish double tap: not the stock notification buzz.
    WKInterfaceDevice.current().play(.click)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
      WKInterfaceDevice.current().play(.click)
    }
  }

  /// Playback for a site actually started (incl. queue → play).
  static func playPlayStart() {
    WKInterfaceDevice.current().play(.success)
  }
}
