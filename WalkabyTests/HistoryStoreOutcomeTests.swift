import Foundation
import Testing

@testable import Walkaby

@MainActor
struct HistoryStoreOutcomeTests {
  @Test func resolveOutcomeUpdatesNewestPendingEvent() {
    let history = HistoryStore.inMemory()
    let event = ProximityEvent(
      date: .now,
      siteSlug: "pura-maospahit",
      siteName: "Pura Maospahit",
      storySlug: "pura-maospahit-01",
      storyTitle: "The Split Gate",
      distanceMeters: 12,
      horizontalAccuracyMeters: 8,
      latitude: -8.6,
      longitude: 115.2,
      wasBackground: false
    )

    history.addEvent(from: event, outcome: .pending)
    let didResolve = history.resolveOutcome(storySlug: "pura-maospahit-01", outcome: .played)

    #expect(didResolve)
    #expect(history.latestOutcome(storySlug: "pura-maospahit-01") == .played)
  }

  @Test func resolveOutcomeIgnoresAlreadyResolvedEvents() {
    let history = HistoryStore.inMemory()
    let event = ProximityEvent(
      date: .now,
      siteSlug: "pura-maospahit",
      siteName: "Pura Maospahit",
      storySlug: "pura-maospahit-01",
      storyTitle: "The Split Gate",
      distanceMeters: 12,
      horizontalAccuracyMeters: 8,
      latitude: -8.6,
      longitude: 115.2,
      wasBackground: false
    )

    history.addEvent(from: event, outcome: .dismissed)
    let didResolve = history.resolveOutcome(storySlug: "pura-maospahit-01", outcome: .played)

    #expect(!didResolve)
    #expect(history.latestOutcome(storySlug: "pura-maospahit-01") == .dismissed)
  }
}
