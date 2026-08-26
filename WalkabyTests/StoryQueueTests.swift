import Testing

@testable import Walkaby

@MainActor
struct StoryQueueTests {
  private func site(_ slug: String, name: String) -> Site {
    Site(
      slug: slug,
      name: name,
      districtName: "Denpasar",
      latitude: 0,
      longitude: 0,
      triggerRadiusMeters: 60,
      headingRequired: false
    )
  }

  private func story(_ slug: String, title: String) -> Story {
    Story(
      slug: slug,
      title: title,
      audioAssetName: "\(slug).m4a",
      transcript: "…",
      durationSeconds: 10
    )
  }

  @Test func enqueuePreservesOrderAndDedupesByStorySlug() {
    let queue = WalkStoryQueue()
    let a = site("a", name: "A")
    let b = site("b", name: "B")
    let storyA = story("a-1", title: "Story A")
    let storyB = story("b-1", title: "Story B")

    queue.enqueue(site: a, story: storyA)
    queue.enqueue(site: b, story: storyB)
    queue.enqueue(site: a, story: storyA)

    #expect(queue.items.map(\.storySlug) == ["a-1", "b-1"])
  }

  @Test func popNextReturnsStoriesInOrder() {
    let queue = WalkStoryQueue()
    queue.enqueue(site: site("a", name: "A"), story: story("a-1", title: "A"))
    queue.enqueue(site: site("b", name: "B"), story: story("b-1", title: "B"))

    #expect(queue.popNext()?.slug == "a-1")
    #expect(queue.popNext()?.slug == "b-1")
    #expect(queue.popNext() == nil)
    #expect(queue.items.isEmpty)
  }

  @Test func clearEmptiesTheQueue() {
    let queue = WalkStoryQueue()
    queue.enqueue(site: site("a", name: "A"), story: story("a-1", title: "A"))
    queue.clear()
    #expect(queue.items.isEmpty)
    #expect(queue.popNext() == nil)
  }
}
