import Testing

@testable import Cooltour

@MainActor
struct WalkSitePlaylistTests {
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

  private func story(_ slug: String, title: String, site: Site) -> Story {
    let story = Story(
      slug: slug,
      title: title,
      audioAssetName: "\(slug).m4a",
      transcript: "…",
      durationSeconds: 10
    )
    story.site = site
    site.stories = [story]
    return story
  }

  private func makePlaylist() -> WalkSitePlaylist {
    WalkSitePlaylistService()
  }

  @Test func `dismissNeverImplied — only enqueue/beginPlaying insert`() {
    let playlist = makePlaylist()

    #expect(playlist.carouselEntries.isEmpty)
    #expect(playlist.playheadIndex == nil)
    #expect(playlist.queuedItems.isEmpty)

    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    playlist.enqueue(site: site1, story: story1)

    #expect(playlist.carouselEntries.count == 1)
    #expect(playlist.carouselEntries.map(\.hasStarted) == [false])

    playlist.clear()

    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)
    _ = playlist.beginPlaying(site: site2, story: story2)

    #expect(playlist.carouselEntries.count == 1)
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true])
    #expect(playlist.playheadIndex == 0)
  }

  @Test func enqueueAppearsAfterPlayhead() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)

    _ = playlist.beginPlaying(site: site1, story: story1)
    playlist.enqueue(site: site2, story: story2)

    #expect(playlist.playheadIndex == 0)
    #expect(playlist.carouselEntries.map(\.siteSlug) == ["site-1", "site-2"])
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true, false])
    #expect(playlist.queuedItems.map(\.storySlug) == ["site-2-01"])
  }

  @Test func beginPlayingParksPriorAndMovesPlayhead() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)

    _ = playlist.beginPlaying(site: site1, story: story1)
    _ = playlist.beginPlaying(site: site2, story: story2)

    #expect(playlist.playheadIndex == 1)
    #expect(playlist.carouselEntries.map(\.siteSlug) == ["site-1", "site-2"])
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true, true])
  }

  @Test func selectEarlierRestartsSameOrder() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)
    let site3 = site("site-3", name: "Site 3")
    let story3 = story("site-3-01", title: "Story 3", site: site3)

    // Play now appends after queue: [1, 3q] + play-now 2 → [1, 3q, 2▶]
    _ = playlist.beginPlaying(site: site1, story: story1)
    playlist.enqueue(site: site3, story: story3)
    _ = playlist.beginPlaying(site: site2, story: story2)

    let selected = playlist.select(index: 0)

    #expect(selected?.site.slug == "site-1")
    #expect(selected?.story.slug == "site-1-01")
    #expect(playlist.playheadIndex == 0)
    #expect(playlist.carouselEntries.map(\.siteSlug) == ["site-1", "site-3", "site-2"])
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true, false, true])
  }

  @Test func playNowAppendsAfterQueuedSites() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)
    let site3 = site("site-3", name: "Site 3")
    let story3 = story("site-3-01", title: "Story 3", site: site3)
    let site4 = site("site-4", name: "Site 4")
    let story4 = story("site-4-01", title: "Story 4", site: site4)

    // [1, 2▶, 3q] + play-now 4 → [1, 2, 3q, 4▶]
    _ = playlist.beginPlaying(site: site1, story: story1)
    _ = playlist.beginPlaying(site: site2, story: story2)
    playlist.enqueue(site: site3, story: story3)
    _ = playlist.beginPlaying(site: site4, story: story4)

    #expect(playlist.carouselEntries.map(\.siteSlug) == ["site-1", "site-2", "site-3", "site-4"])
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true, true, false, true])
    #expect(playlist.playheadIndex == 3)
    #expect(playlist.queuedItems.map(\.storySlug) == ["site-3-01"])
  }

  @Test func advanceAfterFinishPrefersParkedNeighborOverLaterQueue() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)
    let site3 = site("site-3", name: "Site 3")
    let story3 = story("site-3-01", title: "Story 3", site: site3)

    // [1, 2▶] then enqueue 3 → [1, 2▶, 3q]; select 1's neighbor stays before queue
    _ = playlist.beginPlaying(site: site1, story: story1)
    _ = playlist.beginPlaying(site: site2, story: story2)
    playlist.enqueue(site: site3, story: story3)

    #expect(playlist.carouselEntries.map(\.siteSlug) == ["site-1", "site-2", "site-3"])
    #expect(playlist.playheadIndex == 1)

    _ = playlist.select(index: 0)

    #expect(playlist.playheadIndex == 0)

    let next = playlist.advanceAfterFinish()

    #expect(next?.site.slug == "site-2")
    #expect(next?.story.slug == "site-2-01")
    #expect(next?.site.slug != "site-3")
  }

  @Test func selectQueueItemDoesNotReorderNeighbors() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)
    let site3 = site("site-3", name: "Site 3")
    let story3 = story("site-3-01", title: "Story 3", site: site3)

    _ = playlist.beginPlaying(site: site1, story: story1)
    playlist.enqueue(site: site2, story: story2)
    playlist.enqueue(site: site3, story: story3)

    let beforeOrder = playlist.carouselEntries.map(\.siteSlug)
    let selected = playlist.select(index: 2)

    #expect(selected?.site.slug == "site-3")
    #expect(playlist.playheadIndex == 2)
    #expect(playlist.carouselEntries.map(\.siteSlug) == beforeOrder)
    #expect(playlist.carouselEntries.map(\.hasStarted) == [true, false, true])
  }

  @Test func clearEmptiesAll() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)

    _ = playlist.beginPlaying(site: site1, story: story1)
    playlist.enqueue(site: site2, story: story2)

    #expect(playlist.carouselEntries.count >= 1)
    #expect(playlist.playheadIndex != nil || !playlist.queuedItems.isEmpty)

    playlist.clear()

    #expect(playlist.carouselEntries.isEmpty)
    #expect(playlist.playheadIndex == nil)
    #expect(playlist.queuedItems.isEmpty)
  }

  @Test func cannotAdvancePastEndReturnsNil() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)

    _ = playlist.beginPlaying(site: site1, story: story1)

    #expect(playlist.carouselEntries.count == 1)
    #expect(playlist.playheadIndex == 0)

    #expect(playlist.advanceAfterFinish() == nil)
  }

  @Test func siteAtAndStoryAtReturnHeldPair() {
    let playlist = makePlaylist()
    let site1 = site("site-1", name: "Site 1")
    let story1 = story("site-1-01", title: "Story 1", site: site1)
    let site2 = site("site-2", name: "Site 2")
    let story2 = story("site-2-01", title: "Story 2", site: site2)

    _ = playlist.beginPlaying(site: site1, story: story1)
    playlist.enqueue(site: site2, story: story2)

    #expect(playlist.site(at: 0)?.slug == "site-1")
    #expect(playlist.story(at: 0)?.slug == "site-1-01")
    #expect(playlist.site(at: 1)?.slug == "site-2")
    #expect(playlist.story(at: 1)?.slug == "site-2-01")
    #expect(playlist.site(at: 2) == nil)
    #expect(playlist.story(at: -1) == nil)
  }
}
