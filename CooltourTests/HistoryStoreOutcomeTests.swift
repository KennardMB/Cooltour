import Foundation
import Testing

@testable import Cooltour

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

  @Test func stopWalkWithZeroEventsDiscardsWalk() {
    let history = HistoryStore.inMemory()
    history.startWalk()
    #expect(history.activeWalk != nil)

    history.stopWalk()
    #expect(history.activeWalk == nil)
  }

  @Test func stopWalkWithEventsSavesWalk() {
    let history = HistoryStore.inMemory()
    history.startWalk()
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
    history.addEvent(from: event, outcome: .played)
    let active = history.activeWalk
    #expect(active?.triggerEvents.count == 1)

    history.stopWalk()
    #expect(history.activeWalk == nil)
    #expect(active?.endedAt != nil)
  }

  @Test func simulateTriggerOnlyExecutesWhenListening() {
    let engine = MockProximityEngine()
    var triggered = false
    engine.onTrigger = { _, _ in
      triggered = true
    }

    let site = Site(
      slug: "test-site",
      name: "Test Site",
      districtName: "Denpasar",
      latitude: -8.65,
      longitude: 115.21,
      triggerRadiusMeters: 30,
      headingRequired: false
    )
    let story = Story(
      slug: "story-1",
      title: "Story 1",
      audioAssetName: "test_audio",
      transcript: "Transcript",
      durationSeconds: 60
    )
    site.stories.append(story)

    // Not listening -> simulateTrigger does nothing
    engine.simulateTrigger(site: site)
    #expect(triggered == false)

    // Listening -> simulateTrigger fires
    engine.start()
    engine.simulateTrigger(site: site)
    #expect(triggered == true)
  }

  @Test func deleteAllWalksClearsAllHistory() {
    let history = HistoryStore.inMemory()
    history.startWalk()
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
    history.addEvent(from: event, outcome: .played)
    history.stopWalk()

    #expect(!history.recentEvents.isEmpty)

    history.deleteAllWalks()
    #expect(history.activeWalk == nil)
    #expect(history.recentEvents.isEmpty)
  }
}
