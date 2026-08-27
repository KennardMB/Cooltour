# Site Carousel Playlist — Design & Implementation Spec

**Date:** 2026-08-26  
**Status:** design approved — ready to implement  
**Surface:** `SitesPlayerView` site carousel (swipe between stops)

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement Part B task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

---

# Part A — Design (locked)

## Goal

Replace “swipe through every content-pack site” with a **walk-scoped site carousel**: one ordered list + a movable playhead. Swipe **switches audio** (restart from 0:00). Consent-dismissed sites never appear.

## Product rules (locked)

| # | Rule |
|---|---|
| 1 | Swipe **right** → previous sites (left of playhead). Swipe **left** → later sites (right of playhead). |
| 2 | Left side = sites that **already started playing** this walk (not only fully finished listens). |
| 3 | Consent **dismiss** / timeout / pass → site **never** enters the carousel. |
| 4 | Right side = not-yet-started **queued** sites, plus any **parked** started sites that sit after the playhead. |
| 5 | Swipe moves the playhead and **starts that story from 0:00**. |
| 6 | Leaving a site **parks it in place** (same index). Order does not reshuffle. |
| 7 | Returning to a parked site **restarts from the beginning** (no resume). |
| 8 | No swipe past ends: empty history → cannot swipe right; empty right side → cannot swipe left. |
| 9 | Natural finish advances to the **next list entry** (parked neighbor before queue). Must not skip parked sites via blind `popNext()`. |
| 10 | List is walk-scoped: clear with queue when walking mode turns off / end tour. |

### Example (user-validated)

```
[site1][site2 playing][site3 queued]
         ↓ swipe right to site1
[site1 playing][site2 parked][site3 queued]
         ↓ swipe left
[site1][site2 playing][site3 queued]
```

## Architecture

**Approach:** `WalkSitePlaylist` — walk playlist + playhead (Approach 1).

| Piece | Responsibility |
|---|---|
| `WalkSitePlaylist` | Single ordered walk list, playhead, select / beginPlaying / advanceAfterFinish / clear; derived queue listing for the queue sheet |
| `ConsentNarrationCoordinator` | Consent answers; calls playlist on play-now, enqueue, natural finish (no blind queue skip) |
| `StoryQueue` | Kept as the **queued-only** façade used by enqueue paths / sheet, **backed by** (or kept in sync with) playlist — see storage note below |
| `SitesPlayerView` | Carousel binds to `carouselEntries` + `playheadIndex`; swipe → `select` |
| `AudioPlayerService` | Still owns playback; playlist does not call AVFoundation directly — coordinator (or select handler) calls `play(story:)` |

### Storage note (implementation of park-in-place)

Product view is “started + queue.” **Implement as one ordered `entries` array** with a per-entry `hasStarted` flag (or equivalent). Reason: promoting a non-front queue item by `started.append` + `queue.remove` would reorder `[1s,2s,3q,4q]` → `[1s,2s,4s]+[3q]` and break park-in-place. One list keeps absolute positions stable.

Derived views:

- `carouselEntries` → all entries (carousel)
- `queuedItems` → entries where `!hasStarted` (queue sheet / `StoryQueue.items`)
- Left of playhead → swipe-right targets
- Right of playhead → swipe-left targets

## API sketch

```swift
struct WalkPlaylistEntry: Identifiable, Equatable {
  let id: UUID
  let siteSlug: String
  let siteName: String
  let storySlug: String
  let storyTitle: String
  var hasStarted: Bool
  // Site + Story held privately (same pattern as WalkStoryQueue.heldStories)
}

@MainActor
protocol WalkSitePlaylist: AnyObject, Observable {
  var playheadIndex: Int? { get }
  var carouselEntries: [WalkPlaylistEntry] { get }
  /// Never-started entries — same role as today's StoryQueue.items for the sheet.
  var queuedItems: [QueuedStory] { get }

  /// Consent queue / silent enqueue: append never-started entry (de-dupe by story slug).
  func enqueue(site: Site, story: Story)

  /// Play now / first start: append (or mark) as started, set playhead, return whether ready to play.
  /// Prior playhead entry stays in place (parked).
  func beginPlaying(site: Site, story: Story) -> (site: Site, story: Story)?

  /// Carousel swipe: set playhead, mark started, return site+story to play from 0:00.
  func select(index: Int) -> (site: Site, story: Story)?

  /// Natural finish: playhead + 1 if any; mark started; return next or nil.
  func advanceAfterFinish() -> (site: Site, story: Story)?

  func removeQueued(id: UUID)
  func clear()
}
```

## Coordinator wiring

| Event | Playlist | Audio / state |
|---|---|---|
| Consent dismiss / timeout | no-op | existing settle |
| Consent queue / silent enqueue | `enqueue` | existing settle / no play |
| Consent play now | `beginPlaying` (append after queued entries) then `startPlayback` | replaces ear audio; prior entry stays parked; new site lands at list end |
| `playbackDidFinish` | `advanceAfterFinish` then `startPlayback` if non-nil | else idle |
| Carousel swipe | `select(index:)` then `startPlayback` | restart from 0 |
| Walking mode off / end tour | `clear()` | existing clear + stop |

## UI rules (`SitesPlayerView`)

- Data source: `env.playlist.carouselEntries` — **not** `content.allSites()`.
- Selection ↔ `playheadIndex`; on user swipe → `select` + coordinator/audio start.
- Metadata, scrubber, transport follow the **playhead** entry (browse/play split removed).
- Hint copy only advertises available directions.
- Empty list: placeholder, no paging.
- Keep dismiss-when-`prompting` behavior (no fight with consent gate).

## Out of scope

- Persist playlist across walks
- Resume-from-midpoint
- Reorder by drag
- Showing dismissed sites
- Changing consent copy / gate UX

## Acceptance

- [ ] Cannot swipe right with no started sites before playhead
- [ ] Cannot swipe left with nothing after playhead
- [ ] Dismissed / timed-out sites absent from carousel
- [ ] Queued sites appear to the right until started
- [ ] Swipe switches audio from 0:00; parked sites keep index
- [ ] Finish advances to parked neighbor before a later queue item
- [ ] Walking mode off / end tour clears carousel
- [ ] Unit tests cover the rows in Part B Task 1–2

---

# Part B — Implementation Plan

**Goal:** Walk-scoped site carousel with playhead-driven swipe playback.

**Architecture:** `WalkSitePlaylist` owns one ordered walk list + playhead; `ConsentNarrationCoordinator` mutates it on consent/finish; `SitesPlayerView` pages that list and calls `select`.

**Tech Stack:** Swift 6, SwiftUI `TabView` page style, Observation/`@Observable`, Swift Testing

## Global Constraints

- iOS 26.5+, Swift 6 strict concurrency; default `@MainActor`
- Protocol-first services; mock for previews/tests
- Brand name only via `AppConfig.appName`
- No commit / push / PR unless a human explicitly asks
- Do not break attention-test / silence-on-low-confidence / offline-first / privacy principles

## File map

| File | Role |
|---|---|
| Create `Cooltour/Services/Narration/WalkPlaylistEntry.swift` | Entry value type |
| Create `Cooltour/Services/Narration/WalkSitePlaylist.swift` | Protocol |
| Create `Cooltour/Services/Narration/WalkSitePlaylistService.swift` | Real implementation |
| Create `Cooltour/Services/Narration/MockWalkSitePlaylist.swift` | Preview/test double |
| Modify `Cooltour/Services/Narration/ConsentNarrationCoordinator.swift` | Use playlist for play-now / enqueue / finish |
| Modify `Cooltour/Services/Narration/StoryQueue.swift` (+ Walk/Mock) | Either thin-wrap playlist **or** delete call sites and use `playlist.queuedItems` — prefer **playlist owns queue listing**; keep `StoryQueue` type only if still needed as adapter |
| Modify `Cooltour/App/AppEnvironment.swift` | Add `playlist` |
| Modify `Cooltour/CooltourApp.swift` | Construct + inject playlist; clear with walking mode |
| Modify `Cooltour/RootView.swift` | `playlist.clear()` when walking mode off |
| Modify `Cooltour/Features/Now/SitesPlayerView.swift` | Carousel from playlist; swipe → select |
| Modify queue sheet consumers | Read `playlist.queuedItems` (or adapter) |
| Create `CooltourTests/WalkSitePlaylistTests.swift` | Playlist unit tests |
| Modify `CooltourTests/ConsentNarrationCoordinatorTests.swift` | Finish advances parked neighbor |
| Modify / replace `CooltourTests/SitesPlayerSiteSelectionTests.swift` | Index helpers against playlist entries if still needed |
| Modify `Cooltour.xcodeproj/project.pbxproj` | Add new files to targets |

**Recommended decomposition:** Playlist owns enqueue + queued listing. Migrate coordinator + UI off `StoryQueue` as the walk queue source of truth. Keep `QueuedStory` value type. Leave `StoryQueue` protocol as a deprecated adapter **only if** a one-PR migration is too large; preferred end state is playlist-only for walk lists.

---

### Task 1: `WalkSitePlaylist` types + failing tests

**Files:**
- Create: `Cooltour/Services/Narration/WalkPlaylistEntry.swift`
- Create: `Cooltour/Services/Narration/WalkSitePlaylist.swift`
- Create: `CooltourTests/WalkSitePlaylistTests.swift`

**Interfaces:**
- Produces: `WalkPlaylistEntry`, `WalkSitePlaylist` protocol (signatures in Part A)

- [ ] **Step 1: Write failing tests** for:

```swift
@Test func dismissNeverImplied — only enqueue/beginPlaying insert
@Test func enqueueAppearsAfterPlayhead
@Test func beginPlayingParksPriorAndMovesPlayhead
@Test func selectEarlierRestartsSameOrder
@Test func advanceAfterFinishPrefersParkedNeighborOverLaterQueue
@Test func selectQueueItemDoesNotReorderNeighbors
@Test func clearEmptiesAll
@Test func cannotAdvancePastEndReturnsNil
```

Concrete example for parked-neighbor finish:

```swift
// beginPlaying site1; enqueue site3; beginPlaying site2 (play now)
// → entries [1 started, 2 started playhead, 3 queued]
// select(0) → playhead 0
// advanceAfterFinish() → site2 (not site3)
```

- [ ] **Step 2: Run tests — expect compile/link failure** (types missing)

```bash
xcodebuild test -scheme Cooltour -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CooltourTests/WalkSitePlaylistTests
```

- [ ] **Step 3: Add entry + protocol stubs only** (methods `fatalError` / empty) so tests compile and fail on expectations

- [ ] **Step 4: Commit only if human asks**

---

### Task 2: Implement `WalkSitePlaylistService` + mock

**Files:**
- Create: `Cooltour/Services/Narration/WalkSitePlaylistService.swift`
- Create: `Cooltour/Services/Narration/MockWalkSitePlaylist.swift`
- Modify: `Cooltour.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `WalkSitePlaylist`, `WalkPlaylistEntry`, `QueuedStory`, `Site`, `Story`
- Produces: working `WalkSitePlaylistService` / `MockWalkSitePlaylist`

- [ ] **Step 1: Implement one ordered `entries` + `heldSites` / `heldStories` maps** (mirror `WalkStoryQueue`)

- [ ] **Step 2: `enqueue`** — de-dupe by `story.slug`; append `hasStarted = false`

- [ ] **Step 3: `beginPlaying`** — if slug already in list, mark started + move playhead there; else append started + playhead at end

- [ ] **Step 4: `select(index:)`** — bounds-check; mark `hasStarted = true`; set playhead; return held site+story

- [ ] **Step 5: `advanceAfterFinish`** — if `playheadIndex + 1` in range, `select` that index; else nil

- [ ] **Step 6: `queuedItems`** — map `!hasStarted` entries → `QueuedStory`

- [ ] **Step 7: Run `WalkSitePlaylistTests` — all PASS

- [ ] **Step 8: Commit only if human asks**

---

### Task 3: Wire coordinator finish / play-now / enqueue through playlist

**Files:**
- Modify: `Cooltour/Services/Narration/ConsentNarrationCoordinator.swift`
- Modify: `Cooltour/CooltourApp.swift` (init injection)
- Modify: `CooltourTests/ConsentNarrationCoordinatorTests.swift`

**Interfaces:**
- Consumes: `WalkSitePlaylist`
- Produces: coordinator that never skips parked entries on finish

- [ ] **Step 1: Add `playlist` dependency** to `ConsentNarrationCoordinator` init (alongside or replacing direct queue ownership for ordering)

- [ ] **Step 2: `queue` / `enqueueSilently`** → `playlist.enqueue`

- [ ] **Step 3: `accept` / `startPlayback` path** → `playlist.beginPlaying` before `audio.play`

- [ ] **Step 4: Replace `playbackDidFinish` / settle `popNext()`** with:

```swift
if let next = playlist.advanceAfterFinish() {
  _ = startPlayback(next.story, site: next.site)
} else {
  playingSite = nil
  setWayfinding(nil)
  state = .idle
}
```

- [ ] **Step 5: Add test** — play A, enqueue C, play-now B, select A, finish → B plays (not C)

- [ ] **Step 6: Run consent + playlist tests — PASS

- [ ] **Step 7: Commit only if human asks**

---

### Task 4: AppEnvironment + walking-mode clear

**Files:**
- Modify: `Cooltour/App/AppEnvironment.swift`
- Modify: `Cooltour/CooltourApp.swift`
- Modify: `Cooltour/RootView.swift`
- Modify: `Cooltour/Features/Now/SitesPlayerView.swift` (end-tour clear)

- [ ] **Step 1: Add `let playlist: any WalkSitePlaylist`** to `AppEnvironment`; default `MockWalkSitePlaylist()`

- [ ] **Step 2: Production** — `WalkSitePlaylistService()` in `CooltourApp`; pass into coordinator

- [ ] **Step 3: On walking mode off** (RootView) and end tour (SitesPlayerView): `playlist.clear()` together with existing queue clear / stop

- [ ] **Step 4: If `StoryQueue` remains for compatibility, clear both; if migrated, clear playlist only and point queue sheet at `playlist.queuedItems`

- [ ] **Step 5: Build app target — SUCCESS

---

### Task 5: SitesPlayerView carousel behavior

**Files:**
- Modify: `Cooltour/Features/Now/SitesPlayerView.swift`
- Modify: `CooltourTests/SitesPlayerSiteSelectionTests.swift` (update or replace)

- [ ] **Step 1: Replace `availableSites()` carousel source** with `env.playlist.carouselEntries`

- [ ] **Step 2: Bind `TabView` selection to playhead**; on user-driven change call into narration/playlist select + play:

```swift
// Pseudocode — keep wayfinding/state correct by going through coordinator if a method exists,
// else: playlist.select → env.audio.play(story:) and mirror coordinator playingSite carefully.
// Prefer adding NarrationCoordinator.selectPlaylistIndex(_:) that calls playlist.select + startPlayback.
```

- [ ] **Step 3: Add `NarrationCoordinator.selectPlaylistIndex(_:)`** (and mock no-op) so UI does not bypass wayfinding / `state`

- [ ] **Step 4: Hint label** — if playhead == 0, omit “previous”; if playhead == last, omit “next”; if both empty directions, hide hint

- [ ] **Step 5: Empty entries** — show existing empty/placeholder treatment; do not create a one-page phantom swipe

- [ ] **Step 6: Active metadata** — use playhead entry’s site/story (remove browse-vs-playing split)

- [ ] **Step 7: Manual check list** (simulator / device):
  - Walk with one playing story, empty queue → cannot swipe
  - Queue one site → swipe left plays queued from 0; swipe right returns and restarts prior
  - Dismiss at consent → that site never appears
  - Finish while a parked neighbor exists → plays neighbor, not a later queue-only site

- [ ] **Step 8: Commit only if human asks**

---

### Task 6: Queue sheet + cleanup

**Files:**
- Modify: `SitesPlayerView` `StoryQueueSheet` data source
- Modify / remove obsolete `StoryQueue` call sites as decided in Task 3–4
- Update `CooltourTests/StoryQueueTests.swift` only if protocol still exists

- [ ] **Step 1: Queue sheet reads `playlist.queuedItems`** (never-started only)

- [ ] **Step 2: Remove dead code paths** that still page `content.allSites()` in the player

- [ ] **Step 3: Run full `CooltourTests` — PASS

```bash
xcodebuild test -scheme Cooltour -destination 'platform=iOS Simulator,name=iPhone 16'
```

- [ ] **Step 4: Commit only if human asks**

---

## Spec self-review

| Check | Result |
|---|---|
| Placeholder scan | None intentional; coordinator UI bridge explicitly prefers `selectPlaylistIndex` |
| Consistency | Part A rules match Part B tests (park-in-place, restart, dismiss excluded, finish→neighbor) |
| Scope | Single subsystem (player carousel + walk list); no Watch/QR/consent-copy changes |
| Ambiguity | Single ordered list is the required implementation of “started + queue” to avoid reorder bugs |
| Coverage | Rules 1–10 each map to Task 2 tests and/or Task 5 manual checks |

---

## Execution

After human confirms this file looks good:

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — execute tasks in this session with checkpoints  

Which approach?
