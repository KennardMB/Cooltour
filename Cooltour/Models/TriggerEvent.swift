import Foundation

/// One story firing at one place and time. A value type for now — Slice 8 turns walk history
/// into a SwiftData model; this only needs to survive a relaunch well enough to prove a
/// background trigger happened while nobody was looking (see `TriggerLog`).
struct TriggerEvent: Identifiable, Codable, Sendable {
    /// Slug plus timestamp is unique in practice — the evaluator can't fire the same site twice
    /// on one fix — and keeps the type free of a stored UUID that Codable would have to carry.
    var id: String { "\(siteSlug)@\(date.timeIntervalSince1970)" }
    let date: Date
    let siteSlug: String
    let siteName: String
    let storySlug: String
    let storyTitle: String
    let distanceMeters: Double
    let horizontalAccuracyMeters: Double
    /// True when the app wasn't in front. This is the Slice 4 acceptance signal: without
    /// notifications (Slice 4.5) it's the only way to see that a locked-screen trigger fired.
    let wasBackground: Bool
}
