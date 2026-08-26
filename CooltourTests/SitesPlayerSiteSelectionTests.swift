import Testing

@testable import Cooltour

@MainActor
struct SitesPlayerSiteSelectionTests {

  private func makeSite(slug: String, name: String, storySlug: String) -> Site {
    let site = Site(
      slug: slug,
      name: name,
      districtName: "Renon, Denpasar, Bali",
      latitude: -8.6,
      longitude: 115.2,
      triggerRadiusMeters: 60,
      headingRequired: false
    )
    let story = Story(
      slug: storySlug,
      title: "Story",
      audioAssetName: "\(storySlug).m4a",
      transcript: "…",
      durationSeconds: 60
    )
    story.site = site
    site.stories = [story]
    return site
  }

  @Test func siteForStoryFindsOwningSite() {
    let apple = makeSite(
      slug: "apple-developer-academy",
      name: "Apple Developer Academy Bali",
      storySlug: "apple-developer-academy-01"
    )
    let pura = makeSite(
      slug: "pura-dalem-renon",
      name: "Pura Dalem Renon",
      storySlug: "pura-dalem-renon-01"
    )
    let sites = [apple, pura]

    let found = SitesPlayerView.siteForStory(pura.stories.first, in: sites)

    #expect(found?.slug == "pura-dalem-renon")
  }

  @Test func syncIndexMovesCarouselToPlayingStory() {
    let apple = makeSite(
      slug: "apple-developer-academy",
      name: "Apple Developer Academy Bali",
      storySlug: "apple-developer-academy-01"
    )
    let pura = makeSite(
      slug: "pura-dalem-renon",
      name: "Pura Dalem Renon",
      storySlug: "pura-dalem-renon-01"
    )
    let sites = [apple, pura]
    let playingStory = pura.stories.first!

    let index = SitesPlayerView.siteIndex(for: playingStory, in: sites)

    #expect(index == 1)
  }
}
