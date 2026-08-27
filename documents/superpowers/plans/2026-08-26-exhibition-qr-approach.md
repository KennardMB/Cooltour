# Exhibition QR Approach Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a printed QR on an exhibition “site” card open Walkaby and fire the same consent → audio loop as walking into that site, without GPS, NFC tags, or an in-app camera.

**Architecture:** A QR encodes a custom URL `walkaby://approach/<site-slug>`. iOS Camera (or Control Center Code Scanner) opens the installed app. A small parser extracts the slug, looks it up in `ContentStore`, and calls the existing `ProximityEngine.simulateTrigger(site:)` — the same path as **Simulate site approach** on Now. Unknown or malformed URLs stay silent. No new proximity engine, no location spoofing, no Watch changes.

**Tech Stack:** Swift 6, SwiftUI `.onOpenURL`, Info.plist `CFBundleURLTypes`, Swift Testing, existing `LocalContentStore` / `MockProximityEngine`.

## Global Constraints

- Branch from current `main`: `feature/exhibition-qr-approach`. Never commit to `main`.
- Do not `commit` or `push` unless a human explicitly asks in that message (AGENTS.md). Commit steps below are drafts for when they do.
- Swift Testing only (`import Testing`, `@Test`, `#expect`). No new XCTest.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — do not sprinkle `@MainActor` on views; keep URL apply on the main actor (default).
- Brand string in code is `AppConfig.appName` (currently `"Walkaby"`). Do not hardcode the display name in UI copy. The URL **scheme** is a plist literal that cannot read Swift — keep it in sync via `AppConfig.exhibitionApproachURLScheme`.
- Do not add NFC, Core NFC entitlements, an in-app QR scanner, Universal Links, Associated Domains, or an “Exhibition mode” Settings toggle. Those are later if the booth proves they are needed.
- Do not change `CoreLocationProximityEngine` trigger math. QR must go through `simulateTrigger`, which already bypasses GPS accuracy and the re-arm ring (so the same card can be scanned for the next visitor).
- Silence on unknown slug (no error alert). Product principle: a wrong story is worse than nothing. Booth setup is verified by tests + one manual scan before doors open.
- New Swift files under `Cooltour/` join the iOS target automatically (synchronized group). Do **not** put this parser in `Cooltour/SharedCompanion/` — that folder also compiles into the Watch app.
- Pre-existing: `CooltourTests/TestTargetSmokeTests.swift` still expects `AppConfig.appName == "Cooltour"` while `AppConfig.appName` is `"Walkaby"`. Out of scope. Run **only** `ExhibitionApproachURLTests` until someone fixes that smoke test, or expect it to fail if you run the whole suite.

## File map

| File | Responsibility |
|---|---|
| `Cooltour/SharedCompanion/AppConfig.swift` | Scheme + host constants (must match Info.plist). |
| `Cooltour/App/ExhibitionApproachURL.swift` | Parse URL → slug; apply slug → `simulateTrigger`. |
| `Cooltour/Info.plist` | Register `walkaby` URL scheme so Camera can open the app. |
| `Cooltour/RootView.swift` | `.onOpenURL` → apply; jump to Now tab on success. |
| `CooltourTests/ExhibitionApproachURLTests.swift` | Parser + apply coverage. |
| `Testing/exhibition-qr-urls.md` | Copy-paste URLs and booth runbook (print these as QRs). |

**Out of scope files:** `CoreLocationProximityEngine.swift`, Watch targets, Settings UI, Now’s Simulate sheet (leave it as the no-camera backup).

**URL shape (locked):**

```
walkaby://approach/lapangan-niti-mandala-renon
         └── host  └──────── path = site slug ────────┘
```

- `scheme` == `AppConfig.exhibitionApproachURLScheme` (`walkaby`)
- `host` == `AppConfig.exhibitionApproachURLHost` (`approach`)
- `path` == `/<slug>` with exactly one path component (the content-pack **site** slug, not the story slug)

---

### Task 1: Parse approach URLs

**Files:**
- Modify: `Cooltour/SharedCompanion/AppConfig.swift` (append two constants after `appName`)
- Create: `Cooltour/App/ExhibitionApproachURL.swift`
- Test: `CooltourTests/ExhibitionApproachURLTests.swift`

**Interfaces:**
- Consumes: `URL` from iOS
- Produces: `ExhibitionApproachURL.siteSlug(from: URL) -> String?` and the two `AppConfig` constants later tasks must use verbatim

- [ ] **Step 1: Create the branch**

```bash
git checkout main
git pull
git checkout -b feature/exhibition-qr-approach
```

- [ ] **Step 2: Write the failing tests**

Create `CooltourTests/ExhibitionApproachURLTests.swift`:

```swift
import Foundation
import Testing

@testable import Cooltour

struct ExhibitionApproachURLTests {

  @Test func extractsSiteSlugFromApproachURL() {
    let url = URL(string: "walkaby://approach/lapangan-niti-mandala-renon")!
    #expect(
      ExhibitionApproachURL.siteSlug(from: url) == "lapangan-niti-mandala-renon"
    )
  }

  @Test func rejectsWrongScheme() {
    let url = URL(string: "https://example.com/approach/lapangan-niti-mandala-renon")!
    #expect(ExhibitionApproachURL.siteSlug(from: url) == nil)
  }

  @Test func rejectsWrongHost() {
    let url = URL(string: "walkaby://site/lapangan-niti-mandala-renon")!
    #expect(ExhibitionApproachURL.siteSlug(from: url) == nil)
  }

  @Test func rejectsMissingSlug() {
    #expect(ExhibitionApproachURL.siteSlug(from: URL(string: "walkaby://approach")!) == nil)
    #expect(ExhibitionApproachURL.siteSlug(from: URL(string: "walkaby://approach/")!) == nil)
  }

  @Test func rejectsNestedPath() {
    let url = URL(string: "walkaby://approach/renon/lapangan")!
    #expect(ExhibitionApproachURL.siteSlug(from: url) == nil)
  }

  @Test func usesAppConfigSchemeAndHost() {
    let url = URL(
      string:
        "\(AppConfig.exhibitionApproachURLScheme)://\(AppConfig.exhibitionApproachURLHost)/pura-maospahit"
    )!
    #expect(ExhibitionApproachURL.siteSlug(from: url) == "pura-maospahit")
  }
}
```

- [ ] **Step 3: Run tests and confirm they fail**

In Xcode: scheme **Cooltour**, destination any iPhone simulator, run `ExhibitionApproachURLTests`.

Or:

```bash
xcrun simctl list devices available
xcodebuild test -scheme Cooltour \
  -destination 'platform=iOS Simulator,name=<an available iPhone>' \
  -only-testing:CooltourTests/ExhibitionApproachURLTests
```

Expected: compile failure `cannot find 'ExhibitionApproachURL' in scope` (and/or missing `AppConfig` members).

- [ ] **Step 4: Add AppConfig constants**

In `AppConfig`, immediately after `static let appName = "Walkaby"`, add:

```swift
  /// Custom URL scheme registered in `Info.plist` `CFBundleURLTypes`.
  /// Keep the plist string identical — the system cannot read this constant.
  static let exhibitionApproachURLScheme = "walkaby"

  /// Host of `walkaby://approach/<site-slug>`.
  static let exhibitionApproachURLHost = "approach"
```

- [ ] **Step 5: Implement the parser**

Create `Cooltour/App/ExhibitionApproachURL.swift`:

```swift
import Foundation

enum ExhibitionApproachURL {
  /// Site slug if this is a well-formed exhibition approach URL; otherwise `nil`.
  static func siteSlug(from url: URL) -> String? {
    guard url.scheme == AppConfig.exhibitionApproachURLScheme else { return nil }
    guard url.host == AppConfig.exhibitionApproachURLHost else { return nil }

    let trimmed = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    guard !trimmed.isEmpty else { return nil }

    let parts = trimmed.split(separator: "/").map(String.init)
    guard parts.count == 1 else { return nil }
    return parts[0]
  }
}
```

Leave `apply` out of this task so the parser tests stay focused.

- [ ] **Step 6: Re-run tests and confirm they pass**

Same `xcodebuild` / Xcode command as Step 3. Expected: all six tests PASS.

- [ ] **Step 7: Commit (only if a human asked)**

```bash
git add Cooltour/SharedCompanion/AppConfig.swift \
  Cooltour/App/ExhibitionApproachURL.swift \
  CooltourTests/ExhibitionApproachURLTests.swift
git commit -m "$(cat <<'EOF'
Exhibition: parse walkaby://approach/<site-slug> URLs

EOF
)"
```

---

### Task 2: Apply a parsed slug through `simulateTrigger`

**Files:**
- Modify: `Cooltour/App/ExhibitionApproachURL.swift`
- Test: `CooltourTests/ExhibitionApproachURLTests.swift`

**Interfaces:**
- Consumes: `siteSlug(from:)`, `ContentStore.allSites()`, `ProximityEngine.simulateTrigger(site:)`
- Produces: `ExhibitionApproachURL.apply(url:content:proximity:) -> Bool` — `true` only when a matching site with at least one story actually fired

`simulateTrigger` no-ops when `site.stories.first` is nil. Seeded pack sites have stories; do not invent a MockContentStore — use `LocalContentStore.inMemory()`.

- [ ] **Step 1: Write the failing apply tests**

Append to `ExhibitionApproachURLTests.swift` (new `@MainActor` struct so the in-memory store is legal):

```swift
@MainActor
struct ExhibitionApproachURLApplyTests {

  @Test func applyFiresSimulateTriggerForKnownSite() {
    let content = LocalContentStore.inMemory()
    let proximity = MockProximityEngine()
    var triggeredSlug: String?
    proximity.onTrigger = { site, _ in triggeredSlug = site.slug }

    let url = URL(string: "walkaby://approach/lapangan-niti-mandala-renon")!
    let applied = ExhibitionApproachURL.apply(
      url: url,
      content: content,
      proximity: proximity
    )

    #expect(applied)
    #expect(triggeredSlug == "lapangan-niti-mandala-renon")
  }

  @Test func applyStaysSilentForUnknownSlug() {
    let content = LocalContentStore.inMemory()
    let proximity = MockProximityEngine()
    var triggered = false
    proximity.onTrigger = { _, _ in triggered = true }

    let url = URL(string: "walkaby://approach/not-a-real-site")!
    let applied = ExhibitionApproachURL.apply(
      url: url,
      content: content,
      proximity: proximity
    )

    #expect(!applied)
    #expect(!triggered)
  }

  @Test func applyStaysSilentForMalformedURL() {
    let content = LocalContentStore.inMemory()
    let proximity = MockProximityEngine()
    var triggered = false
    proximity.onTrigger = { _, _ in triggered = true }

    let url = URL(string: "https://walkaby.app/renon")!
    let applied = ExhibitionApproachURL.apply(
      url: url,
      content: content,
      proximity: proximity
    )

    #expect(!applied)
    #expect(!triggered)
  }
}
```

- [ ] **Step 2: Run tests and confirm they fail**

Same destination as Task 1, `-only-testing:CooltourTests/ExhibitionApproachURLApplyTests`.

Expected: compile failure `type 'ExhibitionApproachURL' has no member 'apply'`.

- [ ] **Step 3: Implement `apply`**

Add to `ExhibitionApproachURL` in `Cooltour/App/ExhibitionApproachURL.swift`:

```swift
  /// Looks up the site and fires the same path as Now → Simulate site approach.
  /// Returns `false` when the URL is malformed or the slug is not in the pack (stay silent).
  static func apply(
    url: URL,
    content: any ContentStore,
    proximity: any ProximityEngine
  ) -> Bool {
    guard let slug = siteSlug(from: url) else { return false }
    guard let site = content.allSites().first(where: { $0.slug == slug }) else {
      return false
    }
    guard site.stories.first != nil else { return false }
    proximity.simulateTrigger(site: site)
    return true
  }
```

- [ ] **Step 4: Re-run Task 1 + Task 2 tests**

```bash
xcodebuild test -scheme Cooltour \
  -destination 'platform=iOS Simulator,name=<an available iPhone>' \
  -only-testing:CooltourTests/ExhibitionApproachURLTests \
  -only-testing:CooltourTests/ExhibitionApproachURLApplyTests
```

Expected: all PASS. `LocalContentStore.inMemory()` seeds `denpasar` + `renon`, so `lapangan-niti-mandala-renon` must exist.

- [ ] **Step 5: Commit (only if a human asked)**

```bash
git add Cooltour/App/ExhibitionApproachURL.swift \
  CooltourTests/ExhibitionApproachURLTests.swift
git commit -m "$(cat <<'EOF'
Exhibition: map approach URLs onto simulateTrigger

EOF
)"
```

---

### Task 3: Register the scheme and open it from Camera

**Files:**
- Modify: `Cooltour/Info.plist`
- Modify: `Cooltour/RootView.swift`

**Interfaces:**
- Consumes: `ExhibitionApproachURL.apply(url:content:proximity:) -> Bool`
- Produces: Cold-start and warm-start handling via SwiftUI `.onOpenURL`; successful apply selects `AppTab.now` so the consent UI is visible

`GENERATE_INFOPLIST_FILE = YES` merges this file. Add keys alongside the existing `UIBackgroundModes` block; do not remove fonts or background modes.

- [ ] **Step 1: Register `walkaby` in Info.plist**

Inside the top-level `<dict>` of `Cooltour/Info.plist`, add:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>CFBundleURLName</key>
			<string>com.challenge5.Cooltour.approach</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>walkaby</string>
			</array>
		</dict>
	</array>
```

The scheme string **must** equal `AppConfig.exhibitionApproachURLScheme` (`walkaby`).

- [ ] **Step 2: Handle incoming URLs on `RootView`**

`RootView` already has `@Environment(AppEnvironment.self)`. After the existing `.onChange(of: environment.settings.appLanguage)` modifier (before the closing of `body`), add:

```swift
    .onOpenURL { url in
      let applied = ExhibitionApproachURL.apply(
        url: url,
        content: environment.content,
        proximity: environment.proximity
      )
      if applied {
        environment.selectedTab = .now
      }
    }
```

Do not start walking mode. `simulateTrigger` does not need GPS.

- [ ] **Step 3: Build the iOS target**

```bash
xcodebuild build -scheme Cooltour \
  -destination 'platform=iOS Simulator,name=<an available iPhone>'
```

Expected: BUILD SUCCEEDED. Watch target is unchanged.

- [ ] **Step 4: Sanity-check the parser still passes**

Re-run Task 1–2 tests. Expected: PASS.

There is no unit test for Info.plist; that is Task 4’s device scan.

- [ ] **Step 5: Commit (only if a human asked)**

```bash
git add Cooltour/Info.plist Cooltour/RootView.swift
git commit -m "$(cat <<'EOF'
Exhibition: open walkaby://approach URLs from QR scans

EOF
)"
```

---

### Task 4: Booth URLs and runbook

**Files:**
- Create: `Testing/exhibition-qr-urls.md`

No app code. This is what you print. Encode each URL as a **plain URL / text** QR (not Wi-Fi, not vCard) via iPhone Shortcuts → Generate QR Code, or any web QR generator. Print large, high contrast, with a quiet white margin.

- [ ] **Step 1: Write the cheat sheet**

Create `Testing/exhibition-qr-urls.md` with this content (site slugs from `Cooltour/Resources/renon.json` and `denpasar.json` — **site** slugs, not `*-01` story slugs):

```markdown
# Exhibition QR URLs

Encode each line as a QR. Scheme must stay `walkaby`.

## Renon (typical booth set)

| Card label | URL |
|---|---|
| Lapangan Niti Mandala Renon | `walkaby://approach/lapangan-niti-mandala-renon` |
| Bajra Sandhi | `walkaby://approach/monumen-perjuangan-rakyat-bali` |
| Kantor Gubernur Bali | `walkaby://approach/kantor-gubernur-bali` |
| Gedung DPRD Provinsi Bali | `walkaby://approach/gedung-dprd-provinsi-bali` |
| Kawasan Diplomatik Renon | `walkaby://approach/kawasan-diplomatik-renon` |
| Museum Sidik Jari | `walkaby://approach/museum-sidik-jari` |
| Pura Dalem Renon | `walkaby://approach/pura-dalem-renon` |
| Pusat Kuliner Tukad Yeh Aya | `walkaby://approach/pusat-kuliner-tukad-yeh-aya` |

## Denpasar (optional extras)

| Card label | URL |
|---|---|
| Pura Maospahit | `walkaby://approach/pura-maospahit` |
| Pura Jagatnatha | `walkaby://approach/pura-jagatnatha` |
| Museum Bali | `walkaby://approach/museum-bali` |
| Puputan Badung | `walkaby://approach/puputan-badung` |
| Catur Muka | `walkaby://approach/catur-muka` |
| Pasar Badung | `walkaby://approach/pasar-badung` |
| Park 23 | `walkaby://approach/park-23` |
| Apple Developer Academy | `walkaby://approach/apple-developer-academy` |

## Booth runbook

1. Install the **Debug** (or TestFlight) build on the demo iPhone. Visitors’ phones will not open `walkaby://` unless they also have the app.
2. Confirm Now → **Simulate site approach** still works (backup if Camera misbehaves).
3. Open **Camera** (or Control Center → Code Scanner). Point at a printed QR.
4. Tap the system banner to open Walkaby. You should land on Now, hear the approach chime, and see the consent prompt.
5. Play (or Pass) as a real walk would. Scan a **different** card for the next visitor. Scanning the same site again also works: `simulateTrigger` bypasses the GPS re-arm ring.
6. If a scan does nothing: check the QR payload is exactly `walkaby://approach/<slug>` with no spaces, and that the scheme in Info.plist is still `walkaby`.
7. Walking mode can stay **off**. QR does not use GPS.

## What this is not

- Not NFC. Not GPS spoofing. Not a public App Store deep link for strangers.
```

- [ ] **Step 2: Generate one test QR on the iPhone you will demo**

Shortcuts → Generate QR Code → text `walkaby://approach/lapangan-niti-mandala-renon`. Save to Photos. You do not need to commit the image.

- [ ] **Step 3: Commit the markdown (only if a human asked)**

```bash
git add Testing/exhibition-qr-urls.md
git commit -m "$(cat <<'EOF'
Docs: exhibition QR payloads and booth runbook

EOF
)"
```

---

### Task 5: Device verification (required — Camera QR is not in the simulator)

Core NFC is simulator-blocked; custom URL schemes from the **Camera app** are also a real-device (or at least a device-with-Camera) concern. The iOS Simulator can still prove the handler via a typed URL.

- [ ] **Step 1: Simulator URL injection**

Boot the Cooltour scheme on a simulator with the new build. In Terminal:

```bash
xcrun simctl openurl booted 'walkaby://approach/lapangan-niti-mandala-renon'
```

Expected: app comes to foreground (or launches), Now tab, approach chime, consent prompt for Lapangan Niti Mandala Renon.

Then:

```bash
xcrun simctl openurl booted 'walkaby://approach/not-a-real-site'
```

Expected: no new prompt, no crash.

- [ ] **Step 2: Real iPhone**

Install from Xcode. Scan the Photos QR (or a print) with Camera. Tap **Open in Walkaby**. Same prompt as Step 1. Confirm audio plays after Play.

- [ ] **Step 3: Backup path**

With the app already open, Now → Simulate site approach → same site. Expected: identical consent/audio path. If QR fails on the day, use this.

Manual device notes belong in the PR later (AGENTS.md). Do not open a PR unless a human asks.

---

## Self-review

| Requirement | Task |
|---|---|
| QR instead of NFC / no tags to buy | 4 (paper) + 3 (Camera opens app) |
| Same story loop as walking up | 2 (`simulateTrigger`) |
| Demo iPhone, app installed | 4 runbook |
| Unknown slug silent | 2 |
| Repeat scans for next visitor | inherited from `simulateTrigger` (documented in 4) |
| No in-app scanner / no Universal Links | Global Constraints |
| Swift Testing | 1–2 |
| Brand / scheme sync | `AppConfig.exhibitionApproachURLScheme` + plist `walkaby` |
| Device proof | 5 |

No TBD/TODO placeholders. `apply` signature is identical in Task 2 tests, Task 2 implementation, and Task 3 `RootView`.
