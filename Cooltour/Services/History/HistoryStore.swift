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
    guard let walk = activeWalk else { return }
    walk.endedAt = .now
    activeWalk = nil
    try? context.save()
  }
  
  func addEvent(from event: ProximityEvent, wasAutoPlayed: Bool) {
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
      wasAutoPlayed: wasAutoPlayed,
      userLatitude: event.latitude,
      userLongitude: event.longitude,
      wasBackground: event.wasBackground
    )
    context.insert(trigger)
    trigger.walk = walk
    walk.triggerEvents.append(trigger)
    try? context.save()
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
