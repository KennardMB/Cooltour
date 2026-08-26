import SwiftData
import SwiftUI

@MainActor
final class HistoryStore {
  private let container: ModelContainer
  private var context: ModelContext { container.mainContext }
  
  private(set) var activeWalk: Walk?
  
  init(container: ModelContainer) {
    self.container = container
  }
  
  static func inMemory() -> HistoryStore {
    let container = try! ModelContainer(
      for: Walk.self, TriggerEvent.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return HistoryStore(container: container)
  }
  
  func startWalk() {
    if let current = activeWalk, current.endedAt == nil {
      return // Already have an active walk
    }
    
    let walk = Walk(startedAt: .now)
    context.insert(walk)
    activeWalk = walk
    try? context.save()
  }
  
  func stopWalk() {
    guard let walk = activeWalk else {
      cleanupEmptyWalks()
      return
    }
    activeWalk = nil
    if walk.triggerEvents.isEmpty {
      context.delete(walk)
    } else {
      walk.endedAt = .now
    }
    try? context.save()
    cleanupEmptyWalks()
  }

  func cleanupEmptyWalks() {
    let descriptor = FetchDescriptor<Walk>()
    if let allWalks = try? context.fetch(descriptor) {
      for walk in allWalks {
        if walk.triggerEvents.isEmpty {
          context.delete(walk)
        }
      }
      try? context.save()
    }
  }
  
  func addEvent(from event: ProximityEvent, outcome: PromptOutcome) {
    if activeWalk == nil {
      startWalk()
    }
    guard let walk = activeWalk else { return }
    
    let trigger = TriggerEvent(
      siteSlug: event.siteSlug,
      siteName: event.siteName,
      storySlug: event.storySlug,
      storyTitle: event.storyTitle,
      firedAt: event.date,
      outcome: outcome,
      userLatitude: event.latitude,
      userLongitude: event.longitude,
      wasBackground: event.wasBackground
    )
    context.insert(trigger)
    trigger.walk = walk
    walk.triggerEvents.append(trigger)
    try? context.save()
  }

  /// Updates the newest `.pending` event for `storySlug` once the consent gate resolves.
  /// Matching by slug + pending is enough for MVP — one ask per site entry, and the trigger
  /// log always precedes the outcome callback.
  @discardableResult
  func resolveOutcome(storySlug: String, outcome: PromptOutcome) -> Bool {
    guard outcome != .pending else { return false }

    var descriptor = FetchDescriptor<TriggerEvent>(
      predicate: #Predicate {
        $0.storySlug == storySlug && $0.outcome == "pending"
      },
      sortBy: [SortDescriptor(\.firedAt, order: .reverse)]
    )
    descriptor.fetchLimit = 1

    guard let event = (try? context.fetch(descriptor))?.first else { return false }
    event.outcome = outcome.rawValue
    try? context.save()
    return true
  }

  /// Newest stored outcome for a story, if any. Used by tests and the proximity debug surface.
  func latestOutcome(storySlug: String) -> PromptOutcome? {
    var descriptor = FetchDescriptor<TriggerEvent>(
      predicate: #Predicate { $0.storySlug == storySlug },
      sortBy: [SortDescriptor(\.firedAt, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    guard let raw = (try? context.fetch(descriptor))?.first?.outcome else { return nil }
    return PromptOutcome(rawValue: raw)
  }
  
  /// Provides recent events across all walks for the debug view.
  var recentEvents: [ProximityEvent] {
    let descriptor = FetchDescriptor<TriggerEvent>(sortBy: [SortDescriptor(\.firedAt, order: .reverse)])
    let triggers = (try? context.fetch(descriptor)) ?? []
    return triggers.prefix(50).map { trigger in
      ProximityEvent(
        date: trigger.firedAt,
        siteSlug: trigger.siteSlug,
        siteName: trigger.siteName,
        storySlug: trigger.storySlug,
        storyTitle: trigger.storyTitle,
        distanceMeters: 0,
        horizontalAccuracyMeters: 0,
        latitude: trigger.userLatitude,
        longitude: trigger.userLongitude,
        wasBackground: trigger.wasBackground
      )
    }
  }
}
