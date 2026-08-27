import Testing

@testable import Cooltour

@MainActor
struct SitesPlayerSiteSelectionTests {

  @Test func swipeHintHidesWhenEmptyOrSingle() {
    #expect(SitesPlayerView.swipeHint(forIndex: 0, entryCount: 0) == nil)
    #expect(SitesPlayerView.swipeHint(forIndex: 0, entryCount: 1) == nil)
  }

  @Test func swipeHintOmitsPreviousAtStart() {
    let hint = SitesPlayerView.swipeHint(forIndex: 0, entryCount: 3)
    #expect(hint != nil)
    #expect(hint?.localizedCaseInsensitiveContains("previous") == false)
    #expect(hint?.localizedCaseInsensitiveContains("next") == true)
  }

  @Test func swipeHintOmitsNextAtEnd() {
    let hint = SitesPlayerView.swipeHint(forIndex: 2, entryCount: 3)
    #expect(hint != nil)
    #expect(hint?.localizedCaseInsensitiveContains("next") == false)
    #expect(hint?.localizedCaseInsensitiveContains("previous") == true)
  }

  @Test func swipeHintMentionsBothDirectionsInMiddle() {
    let hint = SitesPlayerView.swipeHint(forIndex: 1, entryCount: 3)
    #expect(hint != nil)
    #expect(hint?.localizedCaseInsensitiveContains("previous") == true)
    #expect(hint?.localizedCaseInsensitiveContains("next") == true)
  }

  @Test func userCarouselPageIgnoredWhileSyncing() {
    #expect(
      SitesPlayerView.shouldApplyUserCarouselPage(
        newIndex: 1,
        playheadIndex: 0,
        entryCount: 3,
        isSyncing: true
      ) == false
    )
  }

  @Test func userCarouselPageIgnoredWhenMatchingPlayhead() {
    #expect(
      SitesPlayerView.shouldApplyUserCarouselPage(
        newIndex: 1,
        playheadIndex: 1,
        entryCount: 3,
        isSyncing: false
      ) == false
    )
  }

  @Test func userCarouselPageAppliesWhenIndexDiffers() {
    #expect(
      SitesPlayerView.shouldApplyUserCarouselPage(
        newIndex: 1,
        playheadIndex: 0,
        entryCount: 3,
        isSyncing: false
      ) == true
    )
  }
}
