# WatchSlices.md
### Apple Watch Companion — Slices 17–21

**Source:** [`PRD-AppleWatchCompanion.md`](PRD-AppleWatchCompanion.md) (2026-08-21). That document is
the product spec. This one is the build plan.
**Companion to:** [`InitialCooltour.md`](InitialCooltour.md) §N5 (placeholder, superseded here);
consent / queue / walking mode in [`MilaSlices.md`](MilaSlices.md) (Slices 11, 11.5, 13, 14).
**Status:** ready to build. Do not start until Slice 11 + 11.5 are on the branch you cut from —
Watch answers the same `promptID` the phone already owns.
**Team:** assign owners before cutting branches; slices are sized so two people can run 17→18 and
19 in parallel after the day-1 payload PR merges.

---

## 1. What we are building

A **thin, phone-orchestrated Watch companion**. The wrist does four jobs and nothing else:

| # | Job | Wrist does | Phone still does |
|---|---|---|---|
| J1 | “Something’s nearby — do I want it?” | **Haptic A** + site name + Play / Queue / Dismiss | Proximity, consent TTS, notifications, stem |
| J2 | “Don’t make me pull out my phone” | Now glance + **walking-mode toggle** | `SettingsStore.walkingMode`, proximity start/stop |
| J3 | “I said yes — where do I look?” | **Haptic B** + direction arrow | Playback on iPhone / AirPods; arms/clears the target |
| J4 | Stay silent when unsure | Hide the arrow | Same confidence philosophy as Slice 12 (course first) |

**Audio always plays on the iPhone / AirPods.** The Watch never owns `ProximityEngine`,
`AudioPlayerService`, the content pack, or SwiftData. If that starts to drift, stop — the PRD
rejected Watch-side story audio and Watch-owned proximity.

---

## 2. What is already true on iPhone (do not rebuild)

These landed in Slices 11 / 11.5 / 14. Watch is a new *surface*, not a new *brain*.

| Already exists | Watch uses it as |
|---|---|
| `NarrationCoordinator.accept/queue/dismiss(promptID:)` | The only legal answers. Stale `promptID` is already a no-op. |
| `PendingPrompt` (`Sendable`, no SwiftData) | Consent card input. Add `Codable` in Slice 17; do not invent a second prompt type unless the WC payload must be slimmer. |
| `NarrationState` (`.idle` / `.prompting` / `.playing`) | Glance state. Add `Codable` in Slice 17. |
| `SettingsStore.walkingMode` + `AppConfig.walkingModeKey` | The one switch. Watch writes this store; `RootView` already starts/stops proximity. |
| `dismissCountdownSeconds` on the coordinator | Optional label on Dismiss. |
| `ConsentStrings` play / queue / dismiss + listening copy | Same wording as phone. Compile this file into both targets. |
| `WalkStoryQueue` auto-plays the next item when the current story **finishes** | Matches PRD flow 6.2. Arm wayfinding for B only when B’s playback actually starts. |
| `audio.onPlaybackFinished` | The signal that a queued story may begin (Haptic B + new target). |

**Slice 12 (spoken “on your left”) is not a blocker.** It is not in the tree. The Watch arrow is a
**continuous angle**, not four spoken buckets. Slice 21 implements course-vs-heading selection as
its own pure function. If Slice 12 lands later, it can reuse the heading-picker; do not wait.

---

## 3. Phone gaps this phase must close

Three holes in the running iPhone app. They are small and they block honest Watch behavior. Each
one is owned by a slice below — do not “fix them in passing” on a UI branch.

| Gap | Today | Needed | Slice |
|---|---|---|---|
| Walking mode off mid-prompt | `RootView` stops proximity and clears the queue. The coordinator can stay `.prompting`. | A coordinator method that cancels the open prompt, skips further haptics, and returns to idle. History: `dismissed` (or a new `cancelled` if you want honesty — default `dismissed` to avoid a schema fight). | **18** |
| No “left the site” signal | `ProximityEvaluator` re-arms silently. Nothing tells the rest of the app the walker walked away. | WatchSessionBridge observes `nearbySites` for the current `wayfindingTarget.siteSlug` and clears the target once `distanceMeters > triggerRadiusMeters`. Do **not** wait for the 1.35× re-arm ring — that ring is for not re-prompting, not for keeping an arrow up. | **20** |
| No wayfinding target | Playback start is internal to `startPlayback`. | A flat `WayfindingTarget` published when playback for a site starts, `nil` when it should clear. | **20** |

---

## 4. Architecture (locked by the PRD)

```
ProximityEngine → NarrationCoordinator → AudioPlayerService
                         │
                         ├─→ iPhone Now / notifications / AirPods
                         └─→ WatchSessionBridge  (WatchConnectivity, applicationContext)
                                      │
                                      ▼
                              Cooltour Watch app
                         • Haptic A / Haptic B
                         • Consent (name + 3 actions)
                         • Now glance + walking toggle
                         • Arrow (local course/heading + site coordinate)
```

**Transport rules:**

- Phone → Watch: `WCSession.updateApplicationContext` (latest snapshot wins). Not a GPS firehose.
- Watch → Phone: `sendMessage` for `accept` / `queue` / `dismiss` / `setWalkingMode` so a tap is
  not lost if the Watch app backgrounds. If the phone is unreachable, show the stale/unavailable
  state — do not invent an outcome.
- Activate `WCSession` in `CooltourApp.init`, same reason walking mode starts there: Core Location
  can relaunch a terminated phone into the background with no view.

**Shared code is files-in-two-targets, not a new framework.** Add the same Foundation-only Swift
files to the iPhone app and the Watch app. A Swift package for five structs is speculative.

---

## 5. The slices

### Slice 17 — Watch target + shared payloads
**Branch:** `feature/watch-target-payloads` · **Est:** 1 day
**Goal:** The Watch app installs next to Cooltour and both targets compile the same session types.
This is the day-1 interface PR. Merge it before anyone starts 18–21.

**In scope:**

- Add a **watchOS companion** target (`Cooltour Watch`, bundle `com.challenge5.Cooltour.watchkitapp`).
  Companion to the iPhone app, not an independent Watch app. Deployment: **watchOS 26**, matching
  the iPhone’s iOS 26.5 generation.
- Enable WatchConnectivity on both targets.
- `CooltourWatch/CooltourWatchApp.swift` + a stub `WatchNowView`: app name from `AppConfig.appName`
  only, and a single line that the phone is required. No fake prompt. No fake arrow.
- Shared files compiled into **both** targets (suggested folder `Cooltour/SharedCompanion/`):

  | Type | Role |
  |---|---|
  | `WatchSessionSnapshot` | `Codable` + `Sendable` bag: `walkingModeEnabled`, `narrationState`, `pendingPrompt`, `dismissCountdownSeconds`, `nowPlayingSiteName`, `nowPlayingStoryTitle`, `wayfindingTarget`, `languageCode` |
  | `WayfindingTarget` | `siteSlug`, `siteName`, `latitude`, `longitude`, `triggerRadiusMeters` |
  | `WatchCommand` | Watch → phone: `accept(promptID:)`, `queue(promptID:)`, `dismiss(promptID:)`, `setWalkingMode(Bool)` |
  | `NarrationState` + `PendingPrompt` | Gain `Codable`. Keep them `nonisolated` / `Sendable`. |

- `WatchSessionBridge` protocol + `MockWatchSessionBridge` on the phone. Production impl is
  Slice 18. Wire the mock into `AppEnvironment`’s default init so previews do not activate WC.
- Unit tests: encode → decode round-trip of a full snapshot, a nil-target snapshot, and every
  `WatchCommand`. These live in `CooltourTests` — no Watch hardware.

**Out of scope:** real WC session, haptics, consent taps, Watch location, any coordinator change.

**Acceptance:** iPhone and Watch schemes build. Installing the iPhone app installs the Watch app.
Tests cover payload round-trips. The Watch screen shows `AppConfig.appName` and a “use iPhone”
line. Brand string appears nowhere else.

**Notes:** Add `AppConfig.swift` and `ConsentStrings.swift` to the Watch target in this slice even
if Watch does not call every constant yet — brand name and action labels have one source. Do not
copy `"Cooltour"` into the Watch plist display name as a second source of truth; the watchOS
display name can stay a build setting that matches `AppConfig.appName` until the team rename.

`PendingPrompt.spokenText` will travel in the snapshot. The Watch **must not render it**. Extra
bytes are cheaper than a second prompt type.

---

### Slice 18 — Session bridge + Now glance + walking toggle
**Branch:** `feature/watch-session-glance` · **Est:** 2 days
**Depends on:** Slice 17.

**Goal:** Raise the wrist and see the same walking / listening / prompting / playing state the
phone already has. Flip walking mode on the Watch and the phone starts or stops listening.

**In scope:**

- `WCWatchSessionBridge` on the phone (`Cooltour/Services/Watch/`). Observes
  `settings.walkingMode`, `narration.state`, `narration.pendingPrompt`,
  `narration.dismissCountdownSeconds`, `audio.currentStory` (site/story display names). Pushes a
  new `WatchSessionSnapshot` on meaningful change only.
- Watch-side `WatchSessionClient` (`@Observable`) holds the latest snapshot + `isPhoneReachable`.
- **Now glance states** (PRD §8.1), no extra chrome:

  | Snapshot | Wrist shows |
  |---|---|
  | Phone unreachable / WC inactive | Soft “use iPhone” — do not invent a prompt |
  | `walkingModeEnabled == false` | Walking mode off + toggle |
  | Walking on, `.idle` | `ConsentStrings.statusListening` + toggle |
  | `.prompting` | Site name only (actions arrive in Slice 19). Toggle still visible if it fits; hide if the three buttons need the space — prefer hiding the toggle over crowding. |
  | `.playing` | Site name (from `nowPlayingSiteName`) |

- Watch toggle writes `WatchCommand.setWalkingMode`. Phone applies `settings.walkingMode =`.
  `RootView` already reacts. Do not start/stop proximity from the bridge.
- **`NarrationCoordinator.cancelSession()`** (name can vary; intent cannot): walking mode OFF
  cancels an open prompt, disarms stem/notification, does not play, returns to `.idle`. Call it
  from `RootView`’s existing `walkingMode` `onChange` (the phone Settings/Now toggles need this
  too — it is a product bug, not Watch-only).
- VoiceOver labels and Dynamic Type on the glance. Watch is still an audio product for people
  who are not looking.

**Out of scope:** consent buttons, haptics, arrow, Watch location permission.

**Acceptance:**

- Toggle Watch walking mode on → phone `proximity.isListening` becomes true (simulator: two
  destinations, or a paired device).
- Toggle it off on the Watch while a prompt is open → phone prompt disappears; Watch returns to
  walking-off. Same if the toggle is flipped on the phone.
- Simulate a pura approach on the phone → Watch glance shows the site name without tapping
  anything.
- Disconnect WC (airplane on Watch only, phone still running) → Watch shows unavailable, not a
  tappable ghost prompt.
- Unit tests: bridge (or a pure `makeSnapshot(...)` helper) builds the right snapshot from
  coordinator + settings + audio fixtures. Mock WC. No hardware.

**Notes:** `applicationContext` is latest-wins. That is correct for a glance and wrong for a
command — keep commands on `sendMessage`. If you catch yourself pushing location coordinates at
1 Hz from the phone, you have violated the PRD; delete that path.

---

### Slice 19 — Consent on wrist + Haptic A ⭐ *demo centerpiece*
**Branch:** `feature/watch-consent-haptic-a` · **Est:** 2 days
**Depends on:** Slice 18.

**Goal:** Phone in pocket, AirPods in, walk into a site, wrist buzzes, three taps, same outcomes
as the Now screen.

**In scope:**

- Prompting UI: **site name** + **Play now** / **Add to queue** / **Dismiss**. Labels from
  `ConsentStrings` using `snapshot.languageCode`. Dismiss may show `dismissCountdownSeconds`.
- **Not visible:** spoken prompt line, story title, transcript, direction phrase.
- Taps send `WatchCommand` with the snapshot’s `pendingPrompt.id`. Phone calls the existing
  coordinator methods. First answer wins (stem / notification / Now / Watch); second is a no-op.
- **Haptic A** plays on the Watch when a *new* `pendingPrompt.id` arrives (transition into
  prompting, or a different prompt id). Custom pattern — not `WKHapticType.notification`. Store
  the last-haptic’d prompt id so a duplicate snapshot does not buzz again.
- If WC is late, the haptic follows the state. Wrong-pattern-on-the-phone is not a fallback.
- Walking mode off (Slice 18’s cancel) → Watch leaves the consent UI, **no** Haptic B, no arrow.

**Out of scope:** Haptic B, wayfinding target, arrow, Watch location.

**Acceptance:**

- Device: phone in pocket, walk into a seeded site (or GPX + Watch reachable) → Haptic A, site
  name, three actions.
- Play now on Watch → story plays **once** on phone/AirPods. Stem or notification after that
  does nothing.
- Add to queue while another story is playing → phone queues; Watch leaves consent; current
  playback continues. No new haptic.
- Dismiss or countdown 0 → silence; Watch returns to listening.
- Airplane mode with the paired phone present: the four answers still work.
- Unit tests: Watch-side “should play Haptic A” is a pure function of `(previousPromptID,
  newSnapshot)` — fire on new id, not on countdown ticks, not on identical redelivery.
  Command encoding + stale `promptID` already covered on the phone; add a bridge test that a
  command with a random UUID does not crash and does not play.

**Notes:** Do not request Watch location in this slice. Consent does not need it, and asking
here trains the user to think the Watch is the GPS brain.

---

### Slice 20 — Wayfinding arm + Haptic B
**Branch:** `feature/watch-wayfinding-arm` · **Est:** 1.5 days
**Depends on:** Slice 19 (for the Play-now path that should arm a target). Can start after 18 if
you only drive arming from the phone Now buttons.

**Goal:** The wrist buzzes a *different* pattern when the story they said yes to actually starts —
including when a queued story begins — and the phone publishes the site coordinate for the arrow.

**In scope:**

- `WayfindingTarget` is set **only** inside the coordinator’s `startPlayback` success path (Play
  now, or `playbackDidFinish` / `settleAfterPromptResolved` popping the queue). Queue-only does
  **not** set it.
- Clear `wayfindingTarget` when any of these fire:
  1. Walking mode off (`cancelSession` + existing `RootView` path).
  2. User stops playback (if/when a stop control exists; at minimum, coordinator returning to
     `.idle` with no next story).
  3. Story ended and there is **no** next queued story.
  4. Walker leaves the current target’s `triggerRadiusMeters` (bridge watches `nearbySites`;
     if the slug is missing from the list, treat as left).
- Switching A → B in one `startPlayback` must **replace** the target in a single snapshot.
  Do not publish `nil` in between or Watch will flash Listening and skip Haptic B.
- Snapshot already has the field from Slice 17; this slice is the **policy**.
- **Haptic B** on the Watch when `wayfindingTarget` becomes non-nil or its `siteSlug` changes.
  Clearly different from A. No B on queue-only. No B on clear.
- Playing glance: site name + “playing” affordance. Arrow UI is Slice 21 — without it this
  slice still proves timing.

**Out of scope:** Watch `CLLocationManager`, arrow drawing, heading permission.

**Acceptance:**

- Unit tests (no hardware), the ones the PRD asked for:
  - Arm on playback start, not on `queue(promptID:)`.
  - Clear on walking mode off and on idle-with-empty-queue.
  - Leave-radius: a fixture `nearbySites` list with the target slug beyond
    `triggerRadiusMeters` clears; inside the radius does not.
  - A→B replacement is one snapshot with B’s target, not nil then B.
- Device: Play now on Watch → Haptic B after audio starts (not on the tap).
- Device: queue B while A plays → no Haptic B; when A ends and B starts → Haptic B.
- Device: walking mode off mid-story → target clears, no further B.

**Notes:** Put the arm/clear rules in a small `WayfindingPolicy` (pure, testable) that the
coordinator or bridge calls. Do not bury them in `WCSession` delegate soup. Site lat/lng come
from the `Site` the coordinator already holds in `startPlayback` — thread the `Site` (or a
target value) through that path; do not look the slug up from SwiftData on the Watch.

---

### Slice 21 — Direction arrow
**Branch:** `feature/watch-direction-arrow` · **Est:** 2 days
**Depends on:** Slice 20.

**Goal:** After playback starts, the Watch points at the site they are hearing about. If the
Watch cannot trust which way the body is facing, it shows the site name and **hides the arrow**.

**In scope:**

- Watch Core Location **only while** `wayfindingTarget != nil`. Stop updates the moment the
  phone clears the target. Purpose string in the spirit of: *point toward the cultural site
  you are hearing about.* Request When-In-Use the first time a target arrives, not at launch.
- Permission denied → site name + playing state, no arrow, no nag loop.
- `Cooltour/SharedCompanion/ArrowAngle.swift` — pure functions, no `CLLocation` types in the
  public API (same mould as `ProximityEvaluator`):

  1. `bearingDegrees(from:to:)` — user lat/lng → site lat/lng, 0…360.
  2. `trustedHeadingDegrees(course:courseAccuracy:speedMetersPerSecond:heading:headingAccuracy:)` —
     prefer course when speed is above a walking threshold **and** course accuracy is valid;
     else true heading when accuracy is valid; else `nil`.
  3. `arrowRotationDegrees(bearing:heading:)` — `bearing − heading`, normalized. `nil` in →
     `nil` out.
  4. Hide (return `nil`) when horizontal accuracy is worse than
     `AppConfig.maxLocationAccuracyMeters`.

- Glance: site name + arrow + optional distance while rotation is non-nil. Same screen without
  the arrow when rotation is nil.
- VoiceOver: speak the site name and, when trusted, a coarse relative hint is acceptable
  (“ahead” / “left” / “right” / “behind”) — that is accessibility, not a second UI. Do not
  add a spoken Watch prompt; phone TTS remains the voice.

**Out of scope:** map chrome, complications, Watch-owned proximity, heading as a *trigger* gate
(still `AppConfig.headingRefinement` / N2), streaming angles from the phone.

**Acceptance:**

- Unit tests: 0°/360° wraparound; all four quadrants; course preferred over heading when
  walking; heading used when standing still with a good heading; `nil` when both are junk;
  `nil` when accuracy is worse than 35 m.
- Device, walking toward a seeded site after Play now: arrow aims at the real building.
- Device, stand still with the Watch crown facing a wall (bad heading) or cover GPS: arrow
  **hides**, site name stays.
- Device: leave the radius or turn walking mode off → location updates stop (check in
  debug / Instruments, and say so in the PR).
- Airplane mode + phone present: arrow still works (no network).

**Notes:** Phone-in-pocket is why course comes first on the Watch too — a wrist compass at a
standstill is better than a pocket compass, which is why the hybrid exists, but a spinning
guess still fails the attention test. Hide.

---

## 6. Dependencies

```
Slice 17  payloads + Watch target          ← merge first, like the Slice 11 protocol PR
    ├── Slice 18  bridge + glance + walking toggle
    │       └── Slice 19  consent + Haptic A          ← demo centerpiece
    │               └── Slice 20  wayfinding arm + Haptic B
    │                       └── Slice 21  arrow
    └── Slice 12 (iPhone spoken direction)  ← independent; not on this critical path
```

**Parallelism after 17 merges:** one person can take 18→19 (Watch UI + consent) while another
starts 20’s `WayfindingPolicy` tests on the phone. 21 cannot demo without 20’s target.

**Collision files:**

| File | Who | Rule |
|---|---|---|
| `ConsentNarrationCoordinator.swift` | 18 (`cancelSession`), 20 (`startPlayback` arm) | 18 merges first; 20 rebases. |
| `RootView.swift` | 18 (call `cancelSession` on walking off) | One-line. Do not “also” start WC here — that belongs in `CooltourApp.init`. |
| `AppEnvironment.swift` | 18 (wire production bridge) | Same pattern as notifications. |
| `PendingPrompt` / `NarrationState` | 17 (`Codable`) | Done before anyone else touches them. |

---

## 7. Repo layout after Slice 21

```
Cooltour/
├── SharedCompanion/          // both targets: snapshot, commands, ArrowAngle
├── Services/Watch/           // iPhone: WatchSessionBridge + WC impl + mock
└── …

CooltourWatch/
├── CooltourWatchApp.swift
├── Features/Now/WatchNowView.swift
├── Services/WatchSessionClient.swift
├── Services/WatchHaptics.swift
└── Services/WatchWayfinding.swift   // location loop; math lives in SharedCompanion
```

Do not add Watch folders under `Features/Map`, `Features/History`, or `Features/Settings`.
Those tabs are iPhone-only (PRD non-goals).

---

## 8. Permissions, privacy, attention

- Watch location: When-In-Use, wayfinding only, Slice 21. No Watch microphone.
- No account, no server, no location upload. Arrow math stays on the Watch; the phone already
  has the walk’s GPS for proximity.
- Attention test: no transcript, no map, no scrolling. A raise-and-lower. If a screen needs a
  scroll view, it is wrong.
- Offline-first: WatchConnectivity to the paired phone only. Airplane mode with the phone in
  the pocket must still complete Slices 19–21.

---

## 9. Definition of done for this phase

Matches PRD §12. All device items need real-device notes in the PR (AGENTS.md).

- [ ] Walk into a seeded site, phone in pocket → Haptic A, Watch shows site name + three actions.
- [ ] Play now on Watch → audio on phone/AirPods once; Haptic B; arrow points at the real site
      while walking.
- [ ] Add to queue while another story plays → no arrow yet; when that story starts → Haptic B
      + arrow for *that* site.
- [ ] Dismiss or countdown finish → silence; no Haptic B; no arrow.
- [ ] Walking mode off on Watch → phone stops listening; open prompt cancels; no further A/B.
- [ ] Bad GPS or untrusted heading → arrow hides; site name stays.
- [ ] Airplane mode + phone present: the consent and play-now loop still works.
- [ ] Unit tests for payload round-trip, prompt-id staleness, wayfinding arm-only-on-play,
      and `ArrowAngle` wraparound / low-confidence `nil`.
- [ ] VoiceOver + Dynamic Type on every Watch screen that shipped.
- [ ] `AppConfig.appName` is still the only brand string in code.

---

## 10. Explicitly not these slices

From the PRD. Do not sneak them in because the Watch target exists.

- Watch speaker / Watch-side story audio
- Watch-owned proximity, content pack, or SwiftData
- Arrow during the consent prompt (post-play only)
- Map, History, full Settings, complications, Smart Stack
- Independent Watch GPS walks without the phone
- Relative-direction *spoken* phrase on the Watch
- Rich now-playing transport beyond glance (pause/skip can wait)
- Using heading to gate triggers (`headingRefinement` / N2)

---

## 11. Doc relationships

| Doc | Role after this plan |
|---|---|
| [`PRD-AppleWatchCompanion.md`](PRD-AppleWatchCompanion.md) | Product requirements — do not fork behavior here |
| This file | What to build, in order, with acceptance |
| [`MilaSlices.md`](MilaSlices.md) | Why consent / queue / walking mode exist |
| [`Architecture.md`](Architecture.md) | iPhone service map; update the Watch row when 18 ships |
| [`AGENTS.md`](../AGENTS.md) | Shared types stay UI-agnostic; Watch target is no longer “don’t build” |
