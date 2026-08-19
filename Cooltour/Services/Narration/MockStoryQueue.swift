import Foundation
import Observation

/// Preview/test double — same behaviour as `WalkStoryQueue`, kept separate so production wiring
/// stays obvious in `CooltourApp`.
@Observable
final class MockStoryQueue: StoryQueue {
  private(set) var items: [QueuedStory] = []
  private var heldStories: [UUID: Story] = [:]

  func enqueue(site: Site, story: Story) {
    guard !items.contains(where: { $0.storySlug == story.slug }) else { return }
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
