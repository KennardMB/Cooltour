import Foundation
import Observation

/// Walk-scoped ordered site carousel with a movable playhead (Slice 11.5+).
///
/// Separate from the coordinator so consent rules stay testable without owning list storage, and
/// so Now can observe `carouselEntries` without going through prompt state.
@MainActor
protocol WalkSitePlaylist: AnyObject, Observable {
  var playheadIndex: Int? { get }
  var carouselEntries: [WalkPlaylistEntry] { get }
  var queuedItems: [QueuedStory] { get }

  /// Consent queue / silent enqueue: append never-started entry (de-dupe by story slug).
  func enqueue(site: Site, story: Story)

  /// Play now / first start: append (or mark) as started, set playhead, return site+story to play.
  /// Prior playhead entry stays in place (parked).
  func beginPlaying(site: Site, story: Story) -> (site: Site, story: Story)?

  /// Carousel swipe: set playhead, mark started, return site+story to play from 0:00.
  func select(index: Int) -> (site: Site, story: Story)?

  /// Natural finish: playhead + 1 if any; mark started; return next or nil.
  func advanceAfterFinish() -> (site: Site, story: Story)?

  /// Held site for a carousel index — prefer this over a content-pack lookup.
  func site(at index: Int) -> Site?

  /// Held story for a carousel index.
  func story(at index: Int) -> Story?

  func removeQueued(id: UUID)
  func clear()
}
