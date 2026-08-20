# Regional Packs Slice
### Downloadable city content — Phase 2 of the audio architecture

**Companion to:** [`AudioArchitectureAnalysis.md`](AudioArchitectureAnalysis.md) (this *is* Phase 2), [`MilaSlices.md`](MilaSlices.md), [`InitialCooltour.md`](InitialCooltour.md).
**Branch:** `feature/slice-audio-architecture` (parked)
**Depends on:** Slice 1 (ContentStore), Slice 7 (Settings stub). Independent of Mila slices 12–16. Does **not** wait on Slice 13 — pack notifications use their own category.
**Status:** **Deferred — 2026-08-20.** Exhibition is next week; shipping with **all demo audio in the app bundle** (Phase 1). R2 / downloadable city packs move to the **back of the queue** until after the show. Design below stays valid when we resume; do not start R2 wiring or strip Kuta from the binary for the demo build.

**Exhibition rule:** treat Cooltour as Phase 1 only — offline, zero download step, Denpasar + walk-test sites bundled. Resume this slice when multi-city storage matters again.

This is not Mila-test work. It is the storage/delivery slice the audio architecture called for once Denpasar no longer fits in the app bundle.

---

## 0. Deferral note (post-exhibition resume checklist)

When picking this up again:

1. Re-read this doc and [`docs/superpowers/plans/2026-08-19-regional-packs.md`](../docs/superpowers/plans/2026-08-19-regional-packs.md).
2. Decide whether to keep any in-progress pack library code on `feature/slice-audio-architecture` or re-branch from `main`.
3. Exhibition demo must stay fully playable **without** Settings → Download and **without** a network.
4. R2 (catalog + versioned zips) is still the target hosting; Supabase is still not the playback path.

---

## 1. Goal

The user can download and delete **city packs** (JSON + audio) from a public catalog. Denpasar stays bundled and always works. Playback is always a local file. Nothing streams on a geofence.

> *"Download Kuta (N MB) to hear stories here"* — once, as a notification, when she walks into that city's circle. Not a story. Not a modal. Silence if she says no.

---

## 2. Why this exists

[`AudioArchitectureAnalysis.md`](AudioArchitectureAnalysis.md) ruled out three traps:

1. **Keep stuffing cities into the bundle** — fine for 10–50 Denpasar sites (~6 MB). Wrong at 3–5 cities.
2. **Stream on trigger** — 2–5 s lag, dead zones, lock-screen network kill. Fails the attention test.
3. **A user database** — Cooltour has no accounts and must not upload location. The “database” is a **public catalog of packs**, not Postgres of users.

At 32–48 kbps AAC, 100 stories are ~25 MB. The constraint is **which city is on the phone**, not megabytes.

**Phase 1 (today):** bundled Denpasar. **This slice = Phase 2:** on-demand regional zips. **Phase 3 (later):** predictive LRU cache. Do not pull Phase 3 into this slice.

---

## 3. Decisions (locked)

| Decision | Choice | Why |
|---|---|---|
| Scope | Phase 2 city packs. Denpasar stays in the bundle. | Airplane-mode ADA demo must not require a download. |
| Hosting | Cloudflare R2 + public `catalog.json`. No Supabase, no GitHub Releases. | Audio delivery is CDN bytes, not SQL. R2 has $0 egress. No login. |
| Pack shape | One zip per city (`kuta/1.0.0.zip` = JSON + `.m4a`s). | One Settings row. Matches `ContentPack` as it already exists. |
| Pre-download metadata | **City-geofence only.** Map shows hearable sites, not dimmed Ubud pins. | Avoids Phase 3 complexity and a planner-shaped map. |
| Missing pack | Notification on entering the city circle: Download / Not now. | She asked to be told. Not a full-screen sheet (attention test). |
| Playback | Bundle first, then Application Support. Never HTTP. | Same `AVAudioPlayer` path as today. |
| Updates | Settings shows Update. No auto-download during a walk. | Data use + attention. |
| Streaming / LRU / CMS | Out of scope. | Phase 3 and editorial tools are separate slices. |

---

## 4. Architecture

```
ProximityEngine                    ContentPackLibrary                 AVAudioPlayerService
  site circle → story trigger        catalog + download/delete           plays a file URL
  city circle → pack prompt                  │
                                             ▼
                                    Application Support/Packs/{id}/{version}/
                                             │
                                             ▼
                                    ContentStore seeds that pack's Site/Story rows
```

```
AudioResourceResolver.resolve(audioAssetName, packID)
        │
        ├─ Bundle.main          (Denpasar)
        └─ Application Support  (downloaded pack)
                │
                ├─ Found  → local URL  → AVAudioPlayer
                └─ Missing → do not stream; play nothing
```

**R2 layout (public, anonymous GET):**

```
catalog.json
packs/kuta/1.0.0.zip
```

Immutable versioned zip names. `catalog.json` points at a version. Never `packs/kuta/latest.zip`.

**`catalog.json`:**

```json
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
```

The circle is a **pack prompt**, not a story trigger. Coarse is fine (kilometers). Story radius stays per-site after install.

**Zip contents:**

```
kuta.json          ← same ContentPack shape as denpasar.json
audio/*.m4a
```

---

## 5. Scope

### In

- `AppConfig.contentCatalogURL` — the one place the R2 catalog URL lives.
- `ContentPackLibrary` protocol + `RemoteContentPackLibrary` + `MockContentPackLibrary`. Injected on `AppEnvironment`.
- Fetch/cache `catalog.json`. Last-good cache on disk. Refresh from Settings.
- Download zip with `URLSession` (background so a locked phone can finish). Progress. Cancel. Retry.
- **Atomic install:** unzip to a temp directory → verify `ContentPack` JSON + every `audioFile` exists → move into `Application Support/Packs/{id}/{version}/` → seed SwiftData. On any failure, delete the temp dir and mark `failed`. Never seed a half-pack.
- Delete pack: stop playback if the current story belongs to it, remove files, unseed that pack’s SwiftData rows, re-register the city geofence.
- `Site.packID` (`"bundled"` for Denpasar). Stories inherit it through the site relationship (cascade delete). Bundled reseed must **not** `delete(model: Site.self)` anymore — that would wipe Kuta. Reseed only rows with `packID == AppConfig.bundledPackID`.
- `AudioResourceResolver` used by `AVAudioPlayerService` instead of `Bundle.main` only.
- Proximity: for each catalog pack that is **not** installed, one `CLMonitor` circular condition. Enter + walking mode on → pack-available notification. Not a `onTrigger` story.
- `NotificationService` gains a **pack** category, separate from Slice 13’s story consent: **Download** / **Not now**.
  - Ignore / timeout → do not notify that pack again for **24 hours**.
  - **Not now** → do not notify that pack again until walking mode is turned off (end of this walk).
  - Never more than one delivered pack notification at a time.
- Settings ▸ **Downloaded content** replaces the `"Offline ready"` stub:
  - Denpasar · included · size · not deletable
  - each remote pack · size · version · Download / progress / Delete / Update
  - catalog unreachable → message + Retry
- First remote pack: **extract existing Kuta/Tuban test sites** out of `denpasar.json` into `kuta.json` (Park 23, Academy, Pura Batur Jati, Quest Hotel, Asrama Denkav, Cove Tripuri, Murni Teguh). **Move those `.m4a` files out of `Resources/Audio/` into the zip.** If they stay in the bundle, delete-pack cannot free storage and the resolver’s bundle-first lookup would still find them. No new recordings. Bump bundled `contentPackVersion`.
- Unit tests with a fixture zip in the test bundle (no live R2 required for CI).

### Out

- Streaming fallback
- Predictive LRU / district prefetch (Phase 3)
- Supabase CMS / editor dashboard
- Per-story or per-site downloads
- Auto-download on Wi-Fi
- Dimmed map pins for undownloaded cities
- Download manager on the Now screen
- User accounts, signed URLs, location upload

---

## 6. Data

**New types** (one primary type per file, as usual):

```swift
struct PackCatalog: Decodable {
  var catalogVersion: String
  var packs: [RemotePack]
}

struct RemotePack: Decodable, Identifiable {
  var id: String
  var name: String
  var version: String
  var sizeBytes: Int
  var zipPath: String
  var latitude: Double
  var longitude: Double
  var radiusMeters: Double
}

enum PackStatus: Equatable {
  case notInstalled
  case downloading(progress: Double)  // 0...1
  case installed(version: String, sizeBytes: Int)
  case failed(message: String)
}
```

**SwiftData:** add `packID: String` to `Site` only. Bundled rows use `AppConfig.bundledPackID` (`"bundled"`). The resolver reads `story.site?.packID`. Schema has no `VersionedSchema` yet — `CooltourApp.makeContainer` already wipes on migration; that is acceptable for this MVP change.

**On-disk:**

```
Application Support/
  Packs/
    kuta/
      1.0.0/
        kuta.json
        audio/
          park23-creative-hub-test.m4a
          …
  Catalog/
    catalog.json          ← last successful fetch
```

---

## 7. Logic

**`ContentPackLibrary`** (the one new service):

```swift
protocol ContentPackLibrary: AnyObject {
  var catalog: PackCatalog? { get }
  var lastCatalogError: String? { get }
  func status(for packID: String) -> PackStatus
  func refreshCatalog() async
  func download(_ packID: String) async
  func cancel(_ packID: String)
  func delete(_ packID: String) async
}
```

`AppEnvironment` wires:

- `proximity` city-circle list ← library catalog minus installed
- pack notification **Download** action → `library.download`
- after install/delete → `content` seed/unseed + `proximity.syncMonitor`

**Resolver:** `Bundle.main` then `Packs/{packID}/{version}/audio/{audioAssetName}`. Missing file → log, play nothing (silence on missing asset, same as today).

**Walking mode off:** city geofences are not registered (she is not listening). Settings download still works.

**Version bump:** if `catalog.version != installed.version`, Settings shows Update, which is download-then-replace (atomic: new version in a sibling folder, swap, delete old).

---

## 8. UI

Settings only, plus the notification.

| Surface | Copy / behavior |
|---|---|
| Settings ▸ Downloaded content ▸ Denpasar | “Included with the app” — no delete |
| Remote pack, not installed | “{name} · {size}” + Download |
| Downloading | Progress; Cancel |
| Installed | “{name} · {size} · Delete” |
| Update available | “Update to {version}” |
| Catalog fail | “Can’t refresh packs.” + Retry |
| Notification | “{name} stories available. Download ({size})?” actions: Download, Not now |

VoiceOver labels and Dynamic Type on every new control. Now tab is unchanged.

---

## 9. Failure cases

| Case | Behavior |
|---|---|
| Catalog fetch fails | Use last cached catalog. If none, Settings says so. Denpasar walk unaffected. |
| Download fails / partial zip | Do not seed. Delete temp. `failed` + Retry. |
| Enter city while offline | Notification tells her to download when she has a connection. Tap does not start a story. |
| Disk full | `failed` with that message. Denpasar untouched. |
| Delete while that pack’s story is playing | `audio.stop()` first, then delete. |
| Duplicate slugs across packs | Forbidden. Extracted Kuta sites leave `denpasar.json`. |

---

## 10. Acceptance

- Fresh install, airplane mode: Denpasar walk still works with no catalog fetch.
- Settings lists Denpasar as included and Kuta as downloadable.
- Download Kuta over Wi-Fi → sites appear in the debug content list and on the map; stories play from Application Support; airplane mode after that still plays Kuta.
- Delete Kuta → those sites disappear, files gone, Denpasar untouched, city geofence re-armed.
- Walking mode on, simulate entering the Kuta circle without the pack → one notification; Download installs; Not now does not play a story and does not nag for the rest of the walk.
- Answering twice (notification then Settings) does not corrupt the pack (install is idempotent on version).
- Bundled pack version bump reseeds Denpasar only.
- VoiceOver pass on the new Settings section.
- Unit tests: catalog decode, atomic install rollback on missing audio file, delete unseeds, resolver prefers bundle then pack, city-circle entry does not call `onTrigger`.

Device notes are required in the PR (location + background download + notifications).

---

## 11. Agent notes

- **Protocol-first.** `MockContentPackLibrary` for previews and tests. No `.shared`.
- **Brand name** stays in `AppConfig` only.
- **`ContentStore.seedIfNeeded` today deletes every Site.** That is the first landmine. Fix it before the first successful Kuta install or you will ship a wipe.
- **Do not stream.** If the resolver misses, stay silent. A 3-second spinner on a geofence is the failure mode this slice exists to prevent.
- **Pack prompt ≠ story prompt.** Different notification category, different coordinator. Do not route city-circle entry through `NarrationCoordinator`.
- **R2 is a human setup step.** Create a public bucket, upload `catalog.json` + `packs/kuta/1.0.0.zip`, put the catalog URL in `AppConfig`. Tests must not require the bucket — use a fixture zip.
- **First pack is extracted Kuta/Tuban test sites**, not a fake “Ubud sample.” Real coordinates so a device walk around Park 23 actually exercises the city circle.
- Phase 3 (prefetch 15 nearby clips, 50 MB LRU) is a later slice. Do not add `URLSession` prefetch “while we’re here.”

---

## 12. Relationship to other slices

| Other work | Relationship |
|---|---|
| Slice 7 Settings “Downloaded status: Offline ready” | **Replaced** by this Settings section. |
| Slice 1 `ContentPack` | Unchanged JSON shape; the same decoder loads a zip’s JSON. |
| Slice 13 consent notifications | Separate category. This slice does not block on 13. |
| Slice 14 Now screen | Unchanged. No download UI on Now. |
| Slice 15 chapters | Orthogonal. A downloaded pack can gain `chapterIndex` later. |
| Mila slices 10–12 | Orthogonal. |
| Audio architecture Phase 3 | Explicitly later. |
