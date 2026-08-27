import Testing

@testable import Cooltour

@MainActor
struct NowPlayingInfoLabelsTests {

  private func makeSite(
    name: String = "Pura Maospahit",
    districtName: String = "Renon, Denpasar Selatan"
  ) -> Site {
    Site(
      slug: "pura-maospahit",
      name: name,
      districtName: districtName,
      latitude: -8.6,
      longitude: 115.2,
      triggerRadiusMeters: 60,
      headingRequired: false
    )
  }

  private func makeStory(title: String = "The Split Gate") -> Story {
    Story(
      slug: "pura-maospahit-01",
      title: title,
      audioAssetName: "pura-maospahit-01.m4a",
      transcript: "…",
      durationSeconds: 42
    )
  }

  @Test func titleIsSiteNameAndArtistIsDistrict() {
    let site = makeSite()
    let story = makeStory()
    story.site = site

    #expect(NowPlayingInfoLabels.title(for: story) == "Pura Maospahit")
    #expect(NowPlayingInfoLabels.artist(for: story) == "Renon, Denpasar Selatan")
  }

  @Test func missingSiteFallsBackToStoryTitleAndAppName() {
    let story = makeStory()

    #expect(NowPlayingInfoLabels.title(for: story) == "The Split Gate")
    #expect(NowPlayingInfoLabels.artist(for: story) == AppConfig.appName)
  }

  @Test func blankDistrictFallsBackToAppName() {
    let site = makeSite(districtName: "  ")
    let story = makeStory()
    story.site = site

    #expect(NowPlayingInfoLabels.title(for: story) == "Pura Maospahit")
    #expect(NowPlayingInfoLabels.artist(for: story) == AppConfig.appName)
  }
}
