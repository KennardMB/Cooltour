# InitialCooltour.md
### Slice-by-Slice MVP Development Plan — Cooltour Culture Audio App

**Audience:** AI coding agent (and human reviewers) building the MVP.
**Platform:** iOS (iPhone) first, Apple Watch companion next.
**Language / IDE:** Swift 6 / SwiftUI, Xcode 26+.
**Minimum target:** iOS 26.5.
**Status:** Pre-development. Scope locked. Build in slices, in order.

> **Placeholder name:** "Cooltour" (team) / app codename TBD (e.g. *Nyasar*). Do not hardcode a brand name in more than one place — put it in a single `AppConfig` constant so it can be renamed later.

---

## 0. How to use this document

This is a **slice-based** build plan, not a monolithic spec. Each slice is:

- **Independently shippable** — the app compiles, runs, and does something demonstrable at the end of every slice.
- **Ordered by dependency** — do not start slice N+1 before slice N compiles and its acceptance criteria pass.
- **Vertical** — each slice cuts through data → logic → UI so there's always a runnable app, never a half-built layer.

For each slice you'll find: **Goal · Scope (in/out) · Data · Logic · UI · Acceptance criteria · Agent notes.**

**Golden rule for every slice:** before adding any feature, ask the design test —
> *Does this pull the user's attention onto the device, or push it back out onto the city?*
> If it pulls attention to the screen, it's wrong or it's a fallback. Audio and glance-only interactions win.

---

## 1. About

**Cooltour** is a free-roam, **audio-first** iOS app that plays the story behind a cultural site **the moment the user is physically near it** — no route planning, no searching, no need to look at a screen.

It exists to close one specific gap, validated across five user/stakeholder interviews: solo travelers think of the question *"why is this like this?"* only **after** they've walked away from the thing that sparked it. By then there's no one to ask and no easy way to look it up. Cooltour answers the question **while the user is still standing in front of the thing**, delivered as a short narrated **story** (not encyclopedia facts), keeping the user's eyes on the place and not the phone.

**Inspired by** Kultara, a Bali social enterprise running community walking tours. MVP content is **city-first (Denpasar)**, seeded from Kultara guide storytelling.

---

## 2. Objectives

### Product objectives
1. **Trigger the right story at the right place, in real time** — the core innovation is proximity-triggered content, not route-building.
2. **Stay screen-free by default** — audio is the primary channel; the screen is a fallback/orientation surface.
3. **Make stories stick** — content is narrative and emotional, not factual bullet points ("story sticks, not facts").
4. **Work offline** — a walk must not break because the signal dropped.

### MVP success criteria (demoable)
- User walks a seeded route in Denpasar; stories auto-play as they approach tagged sites, with correct site matching.
- User can toggle auto-play vs. manual, and change playback speed.
- A tappable notification plays the story and expands to a transcript.
- The map tab shows all seeded sites plus the user's live location.
- Everything above works with the device in airplane mode after initial content download.

### Explicit non-goals (MVP)
- No route-builder / itinerary planner.
- No traveler-to-traveler social matching.
- No remote/rural content (no seedable data at MVP scale).
- No account system / login (local-only for MVP; see slice 9 note).
- No AR / visual time-travel (future-vision framing only).

---

## 3. Core User Flow

**Primary loop (the "Now" experience):**

```
User opens app → grants location + notification permission
      ↓
App enters "listening" mode (foreground or background)
      ↓
User walks freely (no plan required)
      ↓
Proximity engine detects: user is within trigger radius of a tagged site
   AND (optionally) heading toward / facing it, AND dwelling
      ↓
   ┌─ Auto-play ON  → story audio begins + notification card drops
   └─ Auto-play OFF → notification only; user taps to play
      ↓
Audio plays (spatial, screen stays in pocket)
      ↓
Story added to "Today's walk" feed on the Now screen
      ↓
Notification/Now card → optional tap → transcript expands (fallback)
      ↓
User keeps walking → next site → repeat
```

**Secondary flow (deliberate / planning — Map tab):**
```
User taps Map tab → sees all seeded sites + own live position →
taps a site pin → sees site detail → can manually play its story
```

**Screen hierarchy (tab bar):**
1. **Now** (home / default) — reactive, in-the-moment. Status line, now-playing card, today's-walk feed, quick controls.
2. **Map** — deliberate/browse. Sites + self-location.
3. **History** — persisted past walks (thin in MVP; see slices).
4. **Settings** — auto/manual, speed, downloads, permissions.

---

## 4. Tech Stack & Frameworks

| Concern | Framework / Tool | Notes |
|---|---|---|
| UI | **SwiftUI** | Primary. Use `@Observable` (Observation framework) for view models, not legacy `ObservableObject` unless a dependency requires it. |
| App lifecycle | **SwiftUI App lifecycle** | `@main App` struct, `Scene`/`WindowGroup`. |
| Location | **Core Location** | `CLLocationManager`; use `CLMonitor` / region monitoring for battery-efficient proximity; standard updates as needed. Request **When In Use** first; **Always** only if background triggering is required (see slice 4). |
| Heading / facing | **Core Location** (`CLHeading`) + **Core Motion** if needed | For "is the user facing the site" refinement. Optional in MVP baseline; behind a confidence flag. |
| Audio playback | **AVFoundation** (`AVAudioEngine` / `AVAudioPlayer`) | Baseline playback + speed control (`AVAudioEngine` time-pitch, or `AVAudioPlayer.rate` with `enableRate`). |
| Spatial audio | **PHASE** (Physical Audio Spatialization Engine) | For spatialized/immersive narration. Introduce in a later slice — do **not** block core playback on it. Baseline audio via AVFoundation first, PHASE as an enhancement layer. |
| Notifications | **UserNotifications** | Local notifications (not push) triggered by proximity events; actionable notification with "Play" + expandable body/transcript. |
| Maps | **MapKit** (SwiftUI `Map`) | Site annotations + user location. |
| Persistence | **SwiftData** | Sites, walk history, (later) photos/journal. Native to Swift, good default. Alternative: Core Data if the agent hits SwiftData limitations. |
| Content packaging | Bundled JSON + local audio files | MVP content ships in-app / pre-downloaded for offline. Model a `ContentPack` so future remote sync is possible. |
| Watch (next) | **WatchKit / SwiftUI on watchOS** + **WatchConnectivity** | Post-iPhone-MVP. Interactable notification + glance. Plan data model to be shareable now; don't build it yet. |
| Weather/time context (optional, later) | **WeatherKit** | Time-of-day/condition matching for narration selection. Nice-to-have, not MVP-critical. |
| Voice content pipeline (offline asset gen, not in-app) | ElevenLabs + RAG-grounded generation | Content is **pre-produced** and bundled; the app just plays files. No runtime AI calls in MVP. |

**Architecture pattern:** MVVM. Feature-foldered. Keep the **proximity engine**, **audio player**, and **content store** as three separate, injectable services behind protocols so they can be tested and swapped (and reused by the Watch target later).

```
CooltourApp/
├── App/                 // entry point, AppConfig, DI container
├── Models/              // SwiftData models: Site, Story, Walk, TriggerEvent
├── Services/
│   ├── Location/        // ProximityEngine (protocol + CLMonitor impl)
│   ├── Audio/           // AudioPlayerService (AVFoundation, later PHASE)
│   ├── Content/         // ContentStore (loads ContentPack, offline)
│   └── Notifications/   // NotificationService
├── Features/
│   ├── Now/             // home tab: status, now-playing, feed
│   ├── Map/             // map tab
│   ├── History/         // history tab
│   └── Settings/        // settings tab
├── Shared/              // reusable UI, extensions, design tokens
└── Resources/           // bundled content pack (JSON + audio), assets
```

**Core principle to encode in the engine:** **silence on low confidence.** If the proximity/matching confidence is below threshold, play **nothing** rather than guessing. A wrong story at the wrong place destroys trust faster than silence.

---

## 5. Data Model (target shape — introduced progressively across slices)

```swift
// SwiftData models (fields may be added slice by slice; this is the end target)

@Model final class Site {
    var id: UUID
    var name: String
    var districtName: String
    var latitude: Double
    var longitude: Double
    var triggerRadiusMeters: Double        // per-site override; default from AppConfig
    var headingRequired: Bool              // does facing matter here?
    var stories: [Story]                   // one or more narrations
    var thumbnailAssetName: String?        // for map/feed; nil = default icon
    // photos added in nice-to-have slice
}

@Model final class Story {
    var id: UUID
    var siteID: UUID
    var title: String
    var audioAssetName: String             // bundled/downloaded file name
    var transcript: String                 // fallback text
    var durationSeconds: Double
    var narratorNote: String?              // e.g. "as told by Keren, Kultara guide"
    var timeOfDayTag: String?              // optional, for later WeatherKit matching
}

@Model final class Walk {                  // a session / day of walking
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var triggerEvents: [TriggerEvent]
}

@Model final class TriggerEvent {          // one story firing at one place/time
    var id: UUID
    var siteID: UUID
    var storyID: UUID
    var firedAt: Date
    var wasAutoPlayed: Bool
    var userLatitude: Double
    var userLongitude: Double
    // photo/journal fields added in nice-to-have slice
}
```

**Content pack (bundled JSON, MVP):**
```json
{
  "contentPackVersion": "1.0.0",
  "region": "Denpasar",
  "sites": [
    {
      "id": "…",
      "name": "Pura Maospahit",
      "district": "…",
      "lat": -8.65, "lng": 115.21,
      "triggerRadiusMeters": 60,
      "headingRequired": false,
      "stories": [
        {
          "id": "…",
          "title": "…",
          "audioFile": "maospahit_01.m4a",
          "transcript": "…",
          "durationSeconds": 95,
          "narratorNote": "as told by a Kultara guide"
        }
      ]
    }
  ]
}
```

---

## 6. The Slices

> Build in this exact order. Each slice ends with a runnable app.

### Slice 0 — Project skeleton & config
**Goal:** A compiling SwiftUI app with the 4-tab shell and dependency scaffolding.
**In scope:**
- Xcode project, iOS 26.5 target, Swift 6, SwiftUI lifecycle.
- `AppConfig` (app name, default trigger radius, feature flags: `autoPlayDefault`, `usePHASE=false`, `headingRefinement=false`).
- Tab bar: **Now / Map / History / Settings** with placeholder screens.
- DI container (simple: an `AppEnvironment` passed via `.environment`).
- Empty service protocols: `ProximityEngine`, `AudioPlayerService`, `ContentStore`, `NotificationService`.
**Out of scope:** any real logic.
**Acceptance:** App launches, all 4 tabs switch, no crashes. Placeholder text per tab.
**Agent notes:** Put the brand name only in `AppConfig`. Keep services protocol-first with a `Preview`/`Mock` implementation each.

---

### Slice 1 — Content store (offline data)
**Goal:** Load the bundled content pack into SwiftData and expose it.
**In scope:**
- SwiftData models `Site` and `Story` (subset of fields needed now).
- Bundle a **sample content pack** (5–8 real Denpasar sites; use placeholder audio + real transcripts if audio isn't ready — a short silent/beep `.m4a` is fine as a stand-in).
- `ContentStore` loads JSON on first launch, seeds SwiftData, and serves `allSites()` / `stories(for:)`.
- Idempotent seeding (don't duplicate on relaunch; key off `contentPackVersion`).
**Out of scope:** downloads/remote sync, audio playback.
**Acceptance:** A debug list view (temporary) shows all seeded sites and their stories, read from SwiftData, working in airplane mode.
**Agent notes:** Model a `ContentPack` loader so a future remote-download path can reuse it. Ship at least placeholder audio files so later slices have something to play.

---

### Slice 2 — Audio playback + speed control
**Goal:** Play a story's audio file with play/pause/seek and adjustable speed.
**In scope:**
- `AudioPlayerService` (AVFoundation) with: `play(story:)`, `pause()`, `resume()`, `stop()`, `setRate(_:)`, published state (`isPlaying`, `currentStory`, `progress`, `rate`).
- Configure `AVAudioSession` for playback (mixes appropriately, plays from pocket / with screen locked).
- Speed control: 0.75× / 1× / 1.25× / 1.5× (via `AVAudioPlayer.rate` with `enableRate`, or `AVAudioEngine` + time-pitch unit).
- Minimal temporary UI: pick a site → play its story → change speed.
**Out of scope:** proximity triggering, spatial/PHASE, notifications.
**Acceptance:** Any seeded story plays end-to-end, pause/resume works, speed changes take effect immediately, audio continues with screen locked.
**Agent notes:** Keep playback logic UI-agnostic (it'll be driven by proximity + notifications later, and by the Watch). Handle interruptions (calls) and route changes (AirPods unplugged) gracefully.

---

### Slice 3 — Proximity engine (foreground)
**Goal:** Detect when the user is near a seeded site and emit a trigger event — foreground first.
**In scope:**
- `ProximityEngine` protocol + Core Location implementation.
- Request **When In Use** location permission with a clear purpose string.
- Compute distance to all sites; when user enters a site's `triggerRadiusMeters`, emit a `TriggerEvent` (debounced so it fires once per entry, with a re-arm distance to avoid flapping).
- **Confidence gate:** require a minimum location accuracy; if GPS accuracy is worse than threshold, do **not** trigger (silence-on-low-confidence).
- Wire trigger → `AudioPlayerService.play` when auto-play is on.
**Out of scope:** background triggering, heading/facing refinement, notifications.
**Acceptance:** Walking (or simulating a GPS route in Xcode) into a site's radius auto-plays its story exactly once; leaving and re-entering re-arms it. Poor-accuracy fixes produce no trigger.
**Agent notes:** Use Xcode's **GPX route simulation** for testing (include a sample `.gpx` that passes through seeded sites). Debounce and hysteresis are essential — test the flapping case explicitly.

---

### Slice 4 — Background triggering + local notifications
**Goal:** Trigger stories while the app is backgrounded/screen-locked, surfaced via a tappable notification.
**In scope:**
- Upgrade to region monitoring via `CLMonitor` (circular conditions per site) for battery-efficient background wake.
- If background triggering requires it, request **Always** location (explain why in the purpose string; degrade gracefully to foreground-only if the user declines).
- `NotificationService`: request notification permission; on trigger, post a **local notification** with the site name + story title, an action button **"Play"**, and body text = story intro.
- Notification tap / "Play" action → opens app to the Now screen with that story playing (or plays directly from the action where feasible).
- Respect the **auto-play setting**: auto ON → play immediately + notification; auto OFF → notification only, user taps to play.
**Out of scope:** transcript expansion UI (next slice), Watch.
**Acceptance:** With the app backgrounded and screen locked, walking into a site posts a notification; tapping it plays the story. Auto-on plays without tap; auto-off waits for tap.
**Agent notes:** Be honest in permission strings — "Always" is a big ask; make the value obvious. If declined, the app must still fully work in foreground. Don't over-notify: one notification per trigger, and a per-site cooldown.

---

### Slice 5 — The "Now" home screen
**Goal:** Build the real home tab: the audio-first, in-the-moment screen.
**In scope (matches the approved lo-fi):**
- **Status line** (top): ambient proximity state — "Listening for nearby stories" / "3 stories nearby" / "Nothing nearby yet."
- **Now card:** current or most-recent triggered story — site name, distance, short snippet, large play/pause button, and a **"Transcript ▾"** disclosure that expands the full transcript inline (fallback, collapsed by default).
- **Quick controls:** auto-play toggle + speed selector as chips (write-through to Settings).
- **"Today's walk" feed:** list of stories triggered this session, each tappable to replay/expand. When nothing's triggered yet, show the nearest upcoming site as a teaser ("Coming up: … — 80m").
**Out of scope:** persisting the feed across launches (that's History), map.
**Acceptance:** Triggering a story updates the Now card and prepends to the feed; transcript expands on demand; controls change playback behavior live; teaser shows nearest site when idle.
**Agent notes:** Transcript stays collapsed by default and framed as fallback — do not make text the primary consumption path. Keep the play target large (thumb-friendly, walking context).

---

### Slice 6 — Map tab
**Goal:** Secondary tab: see all sites and yourself on a map.
**In scope:**
- SwiftUI `Map` with an annotation per seeded site + the user's live location.
- Tap a pin → site detail sheet (name, district, story list, manual **Play**).
- Center-on-me control; show trigger radius optionally (debug toggle).
**Out of scope:** routing/directions, photo pins (nice-to-have slice).
**Acceptance:** All sites appear at correct coordinates; user dot tracks live position; tapping a pin lets the user manually play that site's story.
**Agent notes:** Map is orientation/browse only — do not let it become a route-planner. Reuse `ContentStore` and `AudioPlayerService`; no new playback logic.

---

### Slice 7 — Settings + persistence of preferences
**Goal:** Real settings and durable user preferences.
**In scope:**
- Settings screen: **auto-play on/off**, **default playback speed**, **downloaded content status**, permission shortcuts (deep-link to system settings), about/version.
- Persist preferences (`@AppStorage` / a `SettingsStore`).
- Ensure Now-screen quick controls and Settings stay in sync (single source of truth).
**Out of scope:** multiple content packs / download manager UI (stub is fine).
**Acceptance:** Preferences persist across relaunch; changing them anywhere updates everywhere; auto-play default respected on next trigger.

---

### Slice 8 — Walk history (persisted)
**Goal:** Turn the in-session feed into durable history.
**In scope:**
- `Walk` + `TriggerEvent` SwiftData models; open a `Walk` when listening starts, close it when the session ends.
- History tab: list of past walks; tap → the stories triggered on that walk (replayable).
- This is the persisted version of the Now feed — reuse the same row UI.
**Out of scope:** photos/journal/sharing (next slices).
**Acceptance:** After a walk, History shows it with its triggered stories; stories replay; data survives relaunch and works offline.
**Agent notes:** Keep the schema forward-compatible with photos/journal (nice-to-have) — leave the relationship hooks in `TriggerEvent`.

---

### Slice 9 — Offline hardening & polish (MVP exit)
**Goal:** Make the MVP demo-solid.
**In scope:**
- Verify full loop works in **airplane mode** after first launch (content + audio bundled/pre-downloaded; GPS works offline).
- Empty/edge states: no permission, no sites nearby, GPS lost, audio file missing.
- Battery sanity pass on background monitoring.
- Basic analytics/log hooks (local only) for trigger accuracy debugging.
- Accessibility: VoiceOver labels, Dynamic Type on all screens (audio app — this matters).
**Acceptance:** A clean device, airplane mode after setup, can complete the full walk demo without a network. All four MVP success criteria (§2) pass.

---

## 7. Nice-to-Have Slices (post-MVP, in priority order)

### N1 — PHASE spatial audio upgrade
Swap/augment baseline AVFoundation playback with **PHASE** so narration is spatialized (feels anchored to the site, adapts to head orientation with AirPods). Feature-flagged (`usePHASE`); baseline remains the fallback. *Reason it's not in MVP: it enhances but isn't required for the core proof.*

### N2 — Heading / "facing the site" refinement
Use `CLHeading`/Core Motion so a story fires when the user is **facing** the site, not merely near it — raises trigger precision in dense areas. Behind `headingRefinement` flag.

### N3 — Photo capture → map pin + journal
Let the user take a photo tied to a `TriggerEvent`/site; the **photo replaces the default map pin icon** for that location. Add a lightweight per-entry journal note. Maps to the "process & retain" job. *Watch scope: journal is where creep lives — keep it minimal.*

### N4 — Share photos & route
Export/share a completed walk (stories + photos + path). This is the "retell" job — **not** traveler-matching. Ship last of the three.

### N5 — Apple Watch companion
- watchOS SwiftUI app + **WatchConnectivity** to share content/session with the phone.
- **Interactable notification on the wrist:** glance + tap to play — arguably *more* faithful to screen-free than the phone (eyes stay up).
- Reuse `ProximityEngine`/`AudioPlayerService`/`ContentStore` protocols established in MVP (this is why they're protocol-first from slice 0).
*Order note: Watch is "next" after MVP; the data model is designed now to make it cheap later.*

### N6 — WeatherKit / time-of-day narration matching
Select among multiple stories per site based on time of day / conditions (`timeOfDayTag`). Small, atmospheric enhancement.

---

## 8. Cross-Cutting Requirements

- **Offline-first:** no runtime dependency on network for the core loop. No runtime AI/voice-gen calls — audio is pre-produced and bundled.
- **Silence on low confidence:** never play a guess. Below-threshold accuracy or ambiguous matches → stay quiet.
- **Screen-free bias:** every UI addition is justified against the attention test (§0). Audio and glanceable states are primary; text is fallback.
- **Battery:** prefer region monitoring (`CLMonitor`) over continuous high-accuracy updates for background; profile before shipping each location slice.
- **Permissions honesty:** clear, specific purpose strings; graceful degradation if the user grants less than requested.
- **Privacy:** location stays on-device; no account, no server, no location upload in MVP. Photos (N3) stay local.
- **Testability:** services behind protocols with mock implementations; include a sample `.gpx` route through seeded sites for simulator testing.
- **Content quality is the critical path:** the tech (proximity/notifications/maps) is solved-pattern work; the differentiator is enough *good story-audio* to make a walk feel alive. Structure the content pack so more sites/stories can be added without code changes.

---

## 9. Definition of Done (MVP)

- [ ] Auto/manual play toggle works and is respected on trigger.
- [ ] Playback speed control works live.
- [ ] Proximity auto-plays the correct story once per site entry, with confidence gating.
- [ ] Background trigger posts a tappable notification that plays audio + expands transcript.
- [ ] Now screen: status line, now card, transcript disclosure, today's-walk feed.
- [ ] Map tab: all sites + live user location + manual play.
- [ ] History tab: persisted past walks, replayable.
- [ ] Settings persist and stay in sync with Now quick-controls.
- [ ] Full loop runs in airplane mode after initial setup.
- [ ] VoiceOver + Dynamic Type pass on every screen.

---

## 10. Build order at a glance

```
0 Skeleton → 1 Content store → 2 Audio+speed → 3 Proximity(fg) →
4 Background+notifications → 5 Now screen → 6 Map → 7 Settings →
8 History → 9 Offline hardening  ✅ MVP
     then: N1 PHASE → N2 Heading → N3 Photo/journal → N4 Share → N5 Watch → N6 WeatherKit
```

*Build one slice at a time. Keep it runnable at every step. When in doubt, choose audio over screen, and silence over a wrong guess.*
