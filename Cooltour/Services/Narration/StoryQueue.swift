import Foundation

/// Walk-scoped list of stories she asked to hear later (Slice 11.5). Ordered, de-duplicated by
/// story slug, not persisted — clearing on walking-mode-off keeps it from becoming a reading list.
///
/// Separate from the coordinator so consent rules stay testable without owning list storage, and
/// so Now can observe `items` without going through prompt state.
@MainActor
protocol StoryQueue: AnyObject, Observable {
  var items: [QueuedStory] { get }

  /// Appends if this story slug is not already queued. Holding the `Story` privately so `popNext`
  /// can hand a real model to the player without SwiftData in the value type.
  func enqueue(site: Site, story: Story)

  func remove(id: UUID)
  func clear()

  /// Removes and returns the front story, or nil when empty.
  func popNext() -> Story?
}
