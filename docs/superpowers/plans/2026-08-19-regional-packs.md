# Regional Packs Implementation Plan

> **DEFERRED (2026-08-20):** Exhibition next week. Do **not** execute this plan for the demo build. Ship **Phase 1 — all audio in the app bundle**. Resume R2 / downloadable packs after the show. Spec: [`documents/RegionalPacksSlice.md`](../../../documents/RegionalPacksSlice.md).

> **For agentic workers (when resumed):** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user download and delete a Kuta city pack while Denpasar stays bundled; playback is always a local file and never a stream.

**Architecture:** A `ContentPackLibrary` fetches a catalog, copies/installs a pack into Application Support, and seeds SwiftData by `Site.packID`. The player resolves audio from the bundle first, then the installed pack folder. City-scale geofences prompt a pack download; they never fire a story.

**Tech Stack:** Swift 6, SwiftData, Swift Testing, URLSession, Core Location `CLMonitor`, UserNotifications, AVFoundation. No third-party zip library — packs are an exploded folder (`kuta.json` + `audio/`) that can later be served as a zip from R2.

**Spec:** [`documents/RegionalPacksSlice.md`](../../../documents/RegionalPacksSlice.md)

**Exhibition override:** Prefer merging walk-test sites back into the bundled `denpasar` pack (or shipping whatever is already on `main`) so a visitor never taps Download. Any half-finished pack/R2 work on `feature/slice-audio-architecture` stays parked.

## Global Constraints

- iOS 26.5, Swift 6, `@MainActor` by default; hop off the main actor only for file I/O.
- Protocol-first: `ContentPackLibrary` + `MockContentPackLibrary`. No `.shared`.
- Brand name only in `AppConfig`. Units in names (`radiusMeters`, `sizeBytes`).
- Play only from a local file URL. Missing file → silence, never HTTP.
- Bundled reseed must not delete downloaded packs (`Site.packID`).
- Do not commit unless the human asks. Skip every Commit step.
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`). Run the Cooltour scheme.

## File map

Create:

- `Cooltour/Models/PackCatalog.swift` — catalog JSON
- `Cooltour/Models/RemotePack.swift` — one pack row
- `Cooltour/Models/PackStatus.swift` — install state
- `Cooltour/Services/Audio/AudioResourceResolver.swift`
- `Cooltour/Services/Content/ContentPackLibrary.swift` — protocol
- `Cooltour/Services/Content/LocalContentPackLibrary.swift` — real impl (bundle catalog + copy, later HTTP)
- `Cooltour/Services/Content/MockContentPackLibrary.swift`
- `Cooltour/Services/Content/PackInstaller.swift` — atomic copy/verify/seed
- `Cooltour/Services/Content/PackRegionEvaluator.swift` — city-circle entry, testable
- `Cooltour/Resources/catalog.json`
- `Cooltour/Resources/Packs/kuta/1.0.0/kuta.json` + `audio/*.m4a`
- `CooltourTests/PackCatalogTests.swift`
- `CooltourTests/ContentStorePackTests.swift`
- `CooltourTests/AudioResourceResolverTests.swift`
- `CooltourTests/PackInstallerTests.swift`
- `CooltourTests/PackRegionEvaluatorTests.swift`

Modify:

- `Cooltour/App/AppConfig.swift` — `bundledPackID`, `contentCatalogResourceName`
- `Cooltour/Models/Site.swift` — `packID`
- `Cooltour/Services/Content/ContentStore.swift` — scoped seed, `install`/`uninstall`
- `Cooltour/Services/Audio/AVAudioPlayerService.swift` — resolver
- `Cooltour/Services/Location/ProximityEngine.swift` — pack regions
- `Cooltour/Services/Location/CoreLocationProximityEngine.swift`
- `Cooltour/Services/Notifications/NotificationService.swift`
- `Cooltour/App/AppEnvironment.swift`
- `Cooltour/CooltourApp.swift` — wire library
- `Cooltour/Features/Settings/SettingsView.swift`
- `Cooltour/Resources/denpasar.json` — remove Kuta/Tuban sites, bump version

---

### Task 1: Catalog models

**Files:**
- Create: `Cooltour/Models/RemotePack.swift`
- Create: `Cooltour/Models/PackCatalog.swift`
- Create: `Cooltour/Models/PackStatus.swift`
- Create: `CooltourTests/PackCatalogTests.swift`
- Modify: `Cooltour/App/AppConfig.swift`

**Interfaces:**
- Produces: `RemotePack`, `PackCatalog`, `PackStatus`, `AppConfig.bundledPackID`, `AppConfig.contentCatalogResourceName`

- [ ] **Step 1: Write the failing test**

```swift
import Testing
@testable import Cooltour

struct PackCatalogTests {
  @Test func decodesCatalog() throws {
    let json = """
      {
        "catalogVersion": "1",
        "packs": [
          {
            "id": "kuta",
            "name": "Kuta",
            "version": "1.0.0",
            "sizeBytes": 2400000,
            "zipPath": "packs/kuta/1.0.0.zip",
            "latitude": -8.737,
            "longitude": 115.175,
            "radiusMeters": 8000
          }
        ]
      }
      """
    let catalog = try JSONDecoder().decode(PackCatalog.self, from: Data(json.utf8))
    #expect(catalog.catalogVersion == "1")
    #expect(catalog.packs.count == 1)
    #expect(catalog.packs[0].id == "kuta")
    #expect(catalog.packs[0].radiusMeters == 8000)
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Cooltour -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CooltourTests/PackCatalogTests`

Expected: FAIL — `PackCatalog` not in scope.

- [ ] **Step 3: Write minimal implementation**

`RemotePack.swift` — `Decodable, Identifiable, Equatable, Sendable` with the fields above.

`PackCatalog.swift` — `catalogVersion: String`, `packs: [RemotePack]`.

`PackStatus.swift`:

```swift
enum PackStatus: Equatable {
  case notInstalled
  case downloading(progress: Double)
  case installed(version: String, sizeBytes: Int)
  case failed(message: String)
}
```

`AppConfig`: `bundledPackID = "bundled"`, `contentCatalogResourceName = "catalog"`.

- [ ] **Step 4: Run tests and make sure they pass**

- [ ] **Step 5: Commit** — skip unless the human asks.

---

### Task 2: Scoped SwiftData seed (the wipe landmine)

**Files:**
- Modify: `Cooltour/Models/Site.swift`
- Modify: `Cooltour/Services/Content/ContentStore.swift`
- Create: `CooltourTests/ContentStorePackTests.swift`

**Interfaces:**
- Consumes: `AppConfig.bundledPackID`, `ContentPack`
- Produces: `Site.packID`, `ContentStore.install(_:packID:)`, `ContentStore.uninstall(packID:)`

`seedIfNeeded` today does `context.delete(model: Site.self)` — that would wipe Kuta on every DEBUG launch. Reseed only `packID == bundledPackID`.

- [ ] **Step 1: Write the failing test** using `LocalContentStore` with an in-memory container that includes `Site` and `Story`. Install a second in-memory `ContentPack` with packID `"kuta"`, then call `seedIfNeeded()` and expect the Kuta site to still exist.

Give `Site.init` a `packID: String = AppConfig.bundledPackID` default so existing tests keep compiling.

- [ ] **Step 2: Run test — expect fail** (no `install` / still deletes all).

- [ ] **Step 3: Implement** `packID` on `Site`; `install` replaces rows for that packID then inserts; `uninstall` deletes that packID; `seedIfNeeded` deletes only bundled rows, then inserts bundled with `packID: AppConfig.bundledPackID`; `cachedSites = nil` after every mutation.

- [ ] **Step 4: Run tests.** Also run `ConsentNarrationCoordinatorTests` — `Site(...)` must still compile.

- [ ] **Step 5: Commit** — skip.

---

### Task 3: Audio resource resolver

**Files:**
- Create: `Cooltour/Services/Audio/AudioResourceResolver.swift`
- Create: `CooltourTests/AudioResourceResolverTests.swift`
- Modify: `Cooltour/Services/Audio/AVAudioPlayerService.swift`

**Interfaces:**
- Consumes: `story.audioAssetName`, `story.site?.packID`
- Produces: `AudioResourceResolver.url(for:packID:fileManager:bundle:packsRoot:)`

Resolution order: if `packID` is nil or `bundled`, `Bundle.url(forResource:withExtension:)`. Else `packsRoot/packID/<version>/audio/audioAssetName` — version is the installed folder name; the resolver accepts a concrete directory URL from the library, or scans `packsRoot/packID/*/` for a single version folder.

Never returns an `http` URL.

- [ ] **Step 1: Failing test** — temp directory with `kuta/1.0.0/audio/clip.m4a`; resolve `"clip.m4a"` for pack `"kuta"`; missing file returns nil.

- [ ] **Step 2: Verify fail.**

- [ ] **Step 3: Implement resolver; `AVAudioPlayerService.play` uses it instead of `Bundle.main` only.** Inject `packsRoot` defaulting to Application Support/Packs.

- [ ] **Step 4: Run tests.**

- [ ] **Step 5: Commit** — skip.

---

### Task 4: Atomic pack installer + library

**Files:**
- Create: `Cooltour/Services/Content/PackInstaller.swift`
- Create: `Cooltour/Services/Content/ContentPackLibrary.swift`
- Create: `Cooltour/Services/Content/LocalContentPackLibrary.swift`
- Create: `Cooltour/Services/Content/MockContentPackLibrary.swift`
- Create: `CooltourTests/PackInstallerTests.swift`

**Interfaces:**

```swift
@MainActor
protocol ContentPackLibrary: AnyObject {
  var catalog: PackCatalog? { get }
  var lastCatalogError: String? { get }
  func status(for packID: String) -> PackStatus
  func refreshCatalog() async
  func download(_ packID: String) async
  func cancel(_ packID: String)
  func delete(_ packID: String) async
  func packsRootURL() -> URL
}
```

Installer: copy source directory to `tmp/packID-uuid/` → decode JSON → every `audioFile` exists under `audio/` → move to `Packs/{id}/{version}/` → `content.install`. On failure delete temp and do not seed.

`LocalContentPackLibrary` loads bundled `catalog.json`. For this slice, `zipPath` is a bundle-relative folder (`Packs/kuta/1.0.0`). Download = copy that folder through the installer (stand-in until R2; same atomic path). HTTP zip is a follow-up behind the same `download` method.

- [ ] **Step 1: Failing test** — source dir missing one audio file → install throws, destination absent, store siteCount unchanged.

- [ ] **Step 2: Verify fail.**

- [ ] **Step 3: Implement installer + mock library (in-memory status map) + local library.**

- [ ] **Step 4: Run tests.**

- [ ] **Step 5: Commit** — skip.

---

### Task 5: Extract Kuta pack

**Files:**
- Modify: `Cooltour/Resources/denpasar.json` — drop Kuta/Tuban sites; bump `contentPackVersion` to `0.3.0-placeholder`
- Create: `Cooltour/Resources/Packs/kuta/1.0.0/kuta.json`
- Move audio: `park23-creative-hub-test.m4a`, `pura-batur-jati-test.m4a`, `quest-hotel-kuta-test.m4a`, `asrama-denkav-4-test.m4a`, `cove-tripuri-house-test.m4a`, `murni-teguh-hospital-tuban-test.m4a` into `Packs/kuta/1.0.0/audio/`
- Create: `Cooltour/Resources/catalog.json`
- Fix `park-23` / `apple-developer-academy` `audioFile` from `pasar-badung-01.m4a` to `park23-creative-hub-test.m4a` (do not steal Denpasar audio out of the bundle)

Sites to extract: `park-23`, `apple-developer-academy`, `pura-batur-jati`, `quest-hotel-kuta`, `asrama-denkav-4`, `cove-tripuri-house`, `murni-teguh-hospital-tuban`.

- [ ] **Step 1: No unit test for JSON surgery** — verify by seeding Denpasar in-memory and expecting those slugs absent; Kuta pack JSON decodes as `ContentPack`.

- [ ] **Step 2: Implement the extract + catalog.json** (id kuta, lat -8.737, lng 115.175, radiusMeters 8000).

- [ ] **Step 3: Run ContentStore tests; confirm bundled seed has no `park-23`.**

---

### Task 6: City geofence + pack notifications

**Files:**
- Create: `Cooltour/Services/Content/PackRegionEvaluator.swift`
- Create: `CooltourTests/PackRegionEvaluatorTests.swift`
- Modify: `ProximityEngine.swift`, `CoreLocationProximityEngine.swift`, `NotificationService.swift`

**Interfaces:**
- `PackRegionEvaluator.entered(pack:from:to:)` — true on crossing into `radiusMeters`, re-arm after leaving `radius * AppConfig.reArmRadiusMultiplier`. Does not call `onTrigger`.
- `ProximityEngine.onPackRegionEntered: ((RemotePack) -> Void)?`
- `ProximityEngine.setUninstalledPacks(_: [RemotePack])`
- Monitor identifiers `pack:{id}` so they never collide with site slugs.
- `NotificationService.postPackAvailable(_ pack: RemotePack)`
- Cooldown: ignore 24h; Not now until walking mode off. Extract cooldown to a small `PackPromptCooldown` type so tests don’t need UserNotifications.

Walking mode off → do not register pack circles.

- [ ] Tests for evaluator enter/leave/re-arm and cooldown.
- [ ] Wire `onPackRegionEntered` in `AppEnvironment` to notifications, **not** to `narration.handleTrigger`.

---

### Task 7: Settings UI + DI

**Files:**
- Modify: `AppEnvironment.swift`, `CooltourApp.swift`, `SettingsView.swift`

Replace Settings Content section `"Offline ready"` with:

- Denpasar · Included with the app (not deletable)
- For each catalog pack: status + Download / progress / Delete / Retry
- Catalog error + Retry

Wire `LocalContentPackLibrary` in `CooltourApp` (real) and `MockContentPackLibrary` in `AppEnvironment` default (previews).

On launch, library `refreshCatalog()` then re-seed any packs already on disk if SwiftData lost them.

VoiceOver labels on every new control. No download UI on Now.

---

## Verification

```
xcodebuild test -scheme Cooltour -destination 'platform=iOS Simulator,name=iPhone 16'
```

Manual (device, PR notes): download Kuta, airplane mode, play a Kuta story, delete pack, Denpasar still plays, walking-mode city-circle notification.

R2 upload is a human step after this branch works from the bundled catalog.
