import Foundation
import Observation

@Observable
final class WalkSitePlaylistService: WalkSitePlaylist {
  private(set) var playheadIndex: Int?
  private(set) var carouselEntries: [WalkPlaylistEntry] = []

  /// Kept off the public `WalkPlaylistEntry` so the carousel stays Sendable / SwiftData-free.
  private var heldSites: [UUID: Site] = [:]
  private var heldStories: [UUID: Story] = [:]

  var queuedItems: [QueuedStory] {
    carouselEntries.compactMap { entry in
      guard !entry.hasStarted else { return nil }
      return QueuedStory(
        id: entry.id,
        siteSlug: entry.siteSlug,
        siteName: entry.siteName,
        storySlug: entry.storySlug,
        storyTitle: entry.storyTitle
      )
    }
  }

  func enqueue(site: Site, story: Story) {
    guard !carouselEntries.contains(where: { $0.storySlug == story.slug }) else { return }
    insert(site: site, story: story, hasStarted: false, at: carouselEntries.count)
  }

  func beginPlaying(site: Site, story: Story) -> (site: Site, story: Story)? {
    if let existingIndex = carouselEntries.firstIndex(where: { $0.storySlug == story.slug }) {
      carouselEntries[existingIndex].hasStarted = true
      playheadIndex = existingIndex
      return heldPair(at: existingIndex) ?? (site, story)
    }
    // Play now appends after any queued sites so order stays history → queue → new playhead.
    // Example: [1, 2▶, 3q] + play-now 4 → [1, 2, 3q, 4▶].
    let insertIndex = carouselEntries.count
    insert(site: site, story: story, hasStarted: true, at: insertIndex)
    playheadIndex = insertIndex
    return (site, story)
  }

  func select(index: Int) -> (site: Site, story: Story)? {
    guard carouselEntries.indices.contains(index) else { return nil }
    carouselEntries[index].hasStarted = true
    playheadIndex = index
    return heldPair(at: index)
  }

  func site(at index: Int) -> Site? {
    guard carouselEntries.indices.contains(index) else { return nil }
    return heldPair(at: index)?.site
  }

  func story(at index: Int) -> Story? {
    guard carouselEntries.indices.contains(index) else { return nil }
    return heldPair(at: index)?.story
  }

  func advanceAfterFinish() -> (site: Site, story: Story)? {
    guard let playheadIndex else { return nil }
    let nextIndex = playheadIndex + 1
    guard carouselEntries.indices.contains(nextIndex) else { return nil }
    return select(index: nextIndex)
  }

  func removeQueued(id: UUID) {
    guard let index = carouselEntries.firstIndex(where: { $0.id == id }) else { return }
    guard !carouselEntries[index].hasStarted else { return }
    carouselEntries.remove(at: index)
    heldSites[id] = nil
    heldStories[id] = nil
    if let playhead = playheadIndex {
      if index < playhead {
        playheadIndex = playhead - 1
      } else if index == playhead {
        playheadIndex = carouselEntries.isEmpty ? nil : min(playhead, carouselEntries.count - 1)
      }
    }
  }

  func clear() {
    carouselEntries = []
    playheadIndex = nil
    heldSites = [:]
    heldStories = [:]
  }

  private func insert(site: Site, story: Story, hasStarted: Bool, at index: Int) {
    // Keep the relationship warm so wayfinding can arm when the queue auto-plays (Slice 20).
    if story.site == nil { story.site = site }
    let entry = WalkPlaylistEntry(
      id: UUID(),
      siteSlug: site.slug,
      siteName: site.name,
      storySlug: story.slug,
      storyTitle: story.title,
      hasStarted: hasStarted
    )
    carouselEntries.insert(entry, at: index)
    heldSites[entry.id] = site
    heldStories[entry.id] = story
  }

  private func heldPair(at index: Int) -> (site: Site, story: Story)? {
    let id = carouselEntries[index].id
    guard let site = heldSites[id], let story = heldStories[id] else { return nil }
    return (site, story)
  }
}
