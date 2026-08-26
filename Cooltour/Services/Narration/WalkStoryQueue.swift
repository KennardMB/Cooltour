import Foundation
import Observation

@Observable
final class WalkStoryQueue: StoryQueue {
  private(set) var items: [QueuedStory] = []
  /// Kept off the public `QueuedStory` so the UI list stays Sendable / SwiftData-free.
  private var heldStories: [UUID: Story] = [:]

  func enqueue(site: Site, story: Story) {
    guard !items.contains(where: { $0.storySlug == story.slug }) else { return }
    // Keep the relationship warm so wayfinding can arm when the queue auto-plays (Slice 20).
    if story.site == nil { story.site = site }
    let item = QueuedStory(
      id: UUID(),
      siteSlug: site.slug,
      siteName: site.name,
      storySlug: story.slug,
      storyTitle: story.title
    )
    items.append(item)
    heldStories[item.id] = story
  }

  func remove(id: UUID) {
    items.removeAll { $0.id == id }
    heldStories[id] = nil
  }

  func clear() {
    items = []
    heldStories = [:]
  }

  func popNext() -> Story? {
    guard !items.isEmpty else { return nil }
    let item = items.removeFirst()
    return heldStories.removeValue(forKey: item.id)
  }
}
