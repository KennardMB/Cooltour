# MilaSlices.md
### Post-User-Test Development Plan — Slices 10–16

**Source:** user test with Mila (Apple Developer Academy mentor, solo traveler), Aug 2026.
**Companion to:** [`InitialCooltour.md`](InitialCooltour.md) — that document is still the spec for
everything it covers. This one adds slices 10–16 and supersedes several of its slices (see §3).
Downloadable city audio is **not** a Mila slice — see [`RegionalPacksSlice.md`](RegionalPacksSlice.md)
(**deferred until after the exhibition**, 2026-08-20; demo stays Phase 1 in-app audio).
**Phase length:** 2 weeks. **Team:** Kean, Nanda, Tami.
**Status:** approved, ready to build.
**Revised** during Slice 11 planning: auto-play is deleted rather than redefined, walking mode
replaces it and absorbs background triggering, and the queue becomes Slice 11.5. Slices 11, 13 and
14 changed — Nanda and Tami should re-read §4 and §5 before starting.

---

## 1. What the test told us

Mila's feedback collapses into four jobs. Everything below is downstream of these.

| # | Job | Her words | Status before this phase |
|---|---|---|---|
| J1 | **Ask before you talk** | *"the app should mimic the tour guide: you are approaching X, do you want to know it or paused?"* | Not built. `AppEnvironment` wires trigger → `audio.play` with no way to say no. |
| J2 | **Don't break my audio bubble** | AirPods are a safety net so strangers don't approach; pause music for narration, resume it after | Mostly correct already — but a story that never finishes never releases the session, so her music stays dead for the rest of the walk. |
| J3 | **Speak in my body's frame** | left / right / front / back — *"she hates south-north-east-west"* | Not built. `headingRequired` is stored and never read. |
| J4 | **Short, layered, interruptible** | ≤2 min per stop, 10–12 min per session, *"chunked into smaller pieces"* with an option to hear more | Not built. One ~50s story per site, plays to the end or not at all. |

**Two findings we are deliberately not building:**

- **Session budget (10–12 min).** With ~40s chapters behind a consent prompt, she controls her own
  budget by declining. A countdown would solve a problem the chunking already removes.
- **Car / vehicle mode.** Contradicts the free-roam walking premise and needs a second set of
  shorter recordings. Parked as a post-MVP spike, not cut from the product.

---

## 2. The architectural decision

A new **`NarrationCoordinator`** sits between the proximity engine and the audio player.

```
ProximityEngine          NarrationCoordinator            AudioPlayerService
  decides WHERE     →      decides WHETHER & WHEN     →     decides HOW
(confidence, radius)   (prompt, wait, timeout, chapters)  (file, rate, session)
```

The coordinator owns a state machine, and **walking mode is the outer gate around all of it** — off
means the proximity engine isn't running, so no state is ever entered:

```
idle → prompting → playing → offeringMore → playing → … → idle
          ↓ (dismiss, timeout, or queued)
        idle
```

A trigger arriving while the machine is not `idle` is dropped in Slice 11 and queued in Slice 11.5.
"Left the radius mid-prompt" is a fourth exit that Slice 11 defers — see its notes.

**Why its own service, not a method on `AudioPlayerService`:** the interesting cases — she ignored
the prompt, she walked out mid-prompt, the stem and the notification both answered — have nothing
to do with audio, and testing them inside the player would mean spinning up `AVAudioSession` to
test a countdown. The repo already made this exact split once: `ProximityEvaluator` was carved out
of `CoreLocationProximityEngine` so boundary-flapping could be tested without GPS. Same move.

It also keeps `audio.isPlaying` meaning exactly one thing ("a story is playing") rather than
becoming ambiguous while a prompt is speaking, and it keeps the answer *rules* reusable on the
Watch even though the answer *input* there is a wrist tap rather than an AirPod stem.

### Deliberate exception to the "pre-produced audio" rule

The prompt has to say a runtime-computed site name and direction, which pre-recorded clips can't
cover (13 sites × 4 directions). Prompts use **`AVSpeechSynthesizer`** — on-device, offline, no
network. **Narration stays produced human audio.** AGENTS.md's rule exists to keep the app offline
and keep story quality human; TTS on a four-word wayfinding utterance breaks neither. Flagged here
rather than smuggled in.

---

## 3. Relationship to the original plan

| Original | Fate |
|---|---|
| Slice 4.5 — Local notifications | **Superseded by Slice 13.** Never built; rebuilt with consent actions instead of a bare "Play". |
| Slice 5 — The "Now" home screen | **Superseded by Slice 14.** Never built; reshaped by J1 and J3. |
| Slice 9 — Offline hardening (MVP exit) | Unchanged, still the exit gate, still after all of these. |
| N2 — Heading refinement | **Partly pulled forward as Slice 12**, for *speech*, not for trigger gating. Trigger confidence rules are untouched. |
| Slice 7 — `autoPlay` setting | **Removed by Slice 11.** Nothing auto-plays any more; every story is consented to. See §4, Slice 11. |
| Slice 4/7 — `backgroundTriggering` setting | **Absorbed into walking mode by Slice 11.** One switch, not two. |

Slices 0–4, 6, 7, 8 are done. Numbering continues at 10 to avoid colliding with the existing 9.
Slice 11.5 is a late insert (see §4) and is numbered to sit where it belongs rather than at the end.

---

## 4. The slices

### Slice 10 — Audio session repair
**Owner:** Tami · **Branch:** `bugfix/audio-session-release` · **Est:** 1 day

**Goal:** Her music always comes back.

**The bug:** `stop()` is the only path that deactivates the session, and the only thing that calls
it is the "finished playing" delegate. A story that is paused and never resumed — by a phone call,
by pulling out an AirPod, by her tapping pause — leaves our session active and silent, so Spotify
stays interrupted for the rest of the walk. Separately, `AVAudioSession.interruptionNotification`
with type `.ended` is currently `break`, so a story killed by a phone call never resumes either.

**In scope:**
- Handle `.ended` with the `.shouldResume` option → reactivate session, resume playback.
- Extract a single `endPlayback()` used by `stop()`, the finish delegate, and route-change removal,
  so *every* terminal path releases the session with `.notifyOthersOnDeactivation`.
- Route change `.oldDeviceUnavailable` (AirPods pulled) is **terminal**, not a pause — she has
  stopped listening; release the session.

**Out of scope:** the audio category. `.playback` + `.spokenAudio` hard-interrupts her music rather
than ducking it, which is exactly what she asked for. Do not change it.

**Acceptance:** On a real device, with Spotify playing through AirPods: (a) story triggers → music
pauses → story ends → music resumes; (b) same, but take a phone call mid-story → story resumes
after the call, music resumes after that; (c) same, but pull an AirPod mid-story → story stops,
music resumes. All three in the PR as device test notes.

**Notes:** `AVAudioSession` behavior can't be unit-tested meaningfully; AGENTS.md already requires
device tests for anything touching the audio session, so the PR notes *are* the acceptance surface.

---

### Slice 11 — Walking mode + approach prompt ⭐ *demo centerpiece*
**Owner:** Kean · **Branch:** `feature/slice11-consent-gate` · **Est:** 4 days

**Goal:** *"You're approaching Pura Maospahit. Press play to hear it."* — and silence if she doesn't.

#### 11a — Walking mode replaces auto-play

The original plan kept `autoPlay` and redefined it. We are deleting it instead. After this slice
**nothing ever plays without being asked for**, so a setting called "auto-play" describes a
behavior that no longer exists in either position, and "auto-play OFF" would have meant a prompt
nobody could answer until Slice 13 shipped.

What replaces it is one deliberate switch — **walking mode** — that also absorbs the separate
`backgroundTriggering` toggle. Two switches for one idea was already one too many.

| | Before | After this slice |
|---|---|---|
| `autoPlay` | ON plays instantly · OFF disables the core loop | **gone** |
| `backgroundTriggering` | separate opt-in that escalates to "Always" | **gone, folded into walking mode** |
| listening | implicit, starts in `RootView.onAppear` | **explicit, she turns it on** |

- **ON** → request When-In-Use, escalate to Always on the first fix (the existing
  `refreshAuthorization()` ladder, unchanged), open the `CLBackgroundActivitySession`, register the
  `CLMonitor` conditions, `history.startWalk()`.
- **OFF** → `proximity.stop()` and `syncMonitor(enabled: false)`: live updates cancelled,
  background session invalidated, every geofence deregistered, `history.stopWalk()`.
- **Persisted**, under a renamed `AppConfig.walkingModeKey`, read directly from `UserDefaults` in
  `CooltourApp.init` exactly as `backgroundTriggeringKey` is today. Walking mode surviving app
  termination is the point, not a bug — `CLMonitor` relaunching a terminated app is the whole
  mechanism Slice 4 built. Force-quit is not an off switch; the switch is the off switch.
- **iOS cannot revoke a granted permission from code.** Turning walking mode off stops all *use* of
  location — no wakes, no background indicator, no battery — but Settings will still read "Always"
  until she changes it herself. Say this in the UI rather than implying otherwise.
- **Degraded gracefully:** if she grants only "While Using", walking mode still runs in the
  foreground and while backgrounded-alive; it just won't survive termination. Surface that state on
  the Now screen so unexplained silence is always explained.

#### 11b — The consent gate

- `Services/Narration/NarrationCoordinator.swift` — protocol + `@Observable` implementation, plus
  `MockNarrationCoordinator`. Holds `state: NarrationState` and `pendingPrompt`.
- `PendingPrompt` is a **value type** carrying `id: UUID`, site and story slugs and names, and an
  optional direction phrase — no SwiftData objects. Slice 13's notification body and Slice 14's UI
  render it without a `ModelContainer`, and the tests need no store. The coordinator keeps the real
  `Story` privately for playback. Same reason `ProximityFix` and `NearbySite` already exist.
- `PromptVoice` protocol with one method, `speak(_ text: String)`. `SystemPromptVoice` wraps
  `AVSpeechSynthesizer`; `MockPromptVoice` records what it was asked to say, for tests.
- `ApproachPrompt.text(siteName:directionPhrase:)` — a pure function, nil direction omits the phrase
  entirely. This is the seam Slice 12 plugs into.
- **Two answers this slice: Play now, and Dismiss.** *Add to queue* is real and wanted — it is
  Slice 11.5, immediately after.
- Answer path A: `MPRemoteCommandCenter.playCommand`, armed only while awaiting consent, so the
  AirPod stem answers without touching the phone. Populate `MPNowPlayingInfoCenter` so the lock
  screen shows what's pending. **Disarm the moment the prompt resolves** — a `playCommand` left
  registered holds her play/pause gesture hostage for the rest of the walk, which is Slice 10's
  session leak in a different system. A stem squeeze can only ever carry one meaning, so it maps to
  Play now and nothing else; queueing needs the notification or the screen.
- Timeout: `AppConfig.consentTimeoutSeconds = 20`. No answer → silence.
- **A trigger arriving while the coordinator is not `idle` is ignored.** Prompting over a playing
  story talks across it. Jagatnatha and Museum Bali sit ~30m apart, so this drops a real story on
  the real route — that dropped story is exactly Slice 11.5's first customer, and the
  `ponytail:` note in `CoreLocationProximityEngine.handle(_:)` already anticipated it.
- One ask per site entry. Re-arming is already handled by `ProximityEvaluator`'s re-arm ring —
  reuse it, do not add a second cooldown.
- Rewire `AppEnvironment`: `proximity.onTrigger` now calls the coordinator, not `audio.play`.
- Add `onPlaybackFinished` to `AudioPlayerService` so the coordinator can return to `idle`. Today
  nothing is told when a story ends. **This edits `AVAudioPlayerService.swift`, which Slice 10 also
  rewrites — Kean and Tami coordinate before either merges.**
- **History honesty.** `TriggerEvent.wasAutoPlayed` becomes a lie the moment consent exists, and a
  `Bool` is the wrong shape for three outcomes. Replace it with `outcome: String` backed by a
  `PromptOutcome` enum (`played`, `dismissed`, `timedOut`; `queued` lands in 11.5). Logged at
  trigger time as pending, resolved by the coordinator. No SwiftData migration plan — delete and
  reinstall the dev build.

**Testing infrastructure ships with this slice.** There is no test target in the project at all
today, only a stale script in `Testing/`. Slice 11 adds a Swift Testing unit test target; it cannot
meet its own acceptance criteria without one, and every slice after this benefits.

**Out of scope:** the queue (Slice 11.5), the notification answer path (Slice 13), the on-screen
prompt UI (Slice 14), chapters (Slice 15). Direction in the prompt string is omitted until Slice 12
lands. Stem control *during* playback (squeeze to pause a story) is deliberately not built — it is
cheap once `ConsentRemoteControl` exists, and it partly answers J4's "interruptible", so revisit it
after the demo rather than never.

**Deferred, and say so in the PR:** *leaving the trigger radius mid-prompt cancels the prompt.*
`ProximityEvaluator` already computes the crossing at the 1.35× re-arm ring but throws it away, and
surfacing it means changing `evaluate` and the engine protocol mid-phase while others branch off
them. The 20-second timeout is the only backstop until then, so she can walk ~60m past a site and
still be offered it. Acceptable for week 1; not acceptable at MVP exit.

**Acceptance:** Simulating the GPX route with walking mode on, entering a radius speaks the prompt
and plays nothing until answered. Stem press plays the story. Twenty seconds of silence plays
nothing and records a `timedOut` outcome. Turning walking mode off mid-walk stops all wakes.
Unit tests cover: timeout, dismiss, accept, double-answer idempotency, a stale `promptID` being
ignored, and a trigger arriving mid-playback being ignored — all against `MockAudioPlayerService`
and `MockPromptVoice`, no hardware.

**Notes:** Inject the timeout as a `Duration` and expose the timeout `Task` so tests await it
deterministically instead of sleeping. This slice ships first because it's the demo; it ships
without the direction phrase rather than waiting on Slice 12.

---

### Slice 11.5 — Story queue
**Owner:** Kean · **Branch:** `feature/story-queue` · **Est:** 2 days
**Depends on:** Slice 11.

**Goal:** The third answer — *"not now, but keep it for me."*

**The rule that makes it safe:** a queued story **only ever plays when she asks for it**, from the
Now screen. Never on a timer, never when the current story ends, never on re-entry. A story about
Pura Maospahit narrated twenty minutes later while she is standing somewhere else is precisely the
"wrong story at the wrong place" the product principles exist to prevent. The queue is a saved
list, not a playlist.

**In scope:**
- A third prompt answer, `queue(promptID:)`, resolving the same `PendingPrompt` as the other two
  and recording a `queued` outcome.
- Queue storage on the coordinator — ordered, de-duplicated by story slug, and **not** persisted
  across walks. A queue that outlives the walk is a reading list, which is a different product.
- The dropped-collision case: when a trigger arrives while the coordinator is busy, queue it
  silently instead of discarding it, and let her know it's there rather than interrupting. This is
  the Jagatnatha / Museum Bali problem, which is on the real Denpasar route.
- A queue list on the Now screen: what's waiting, tap to play, swipe to remove, clear on walk end.
- The third action on the notification and on the on-screen prompt. This slice owns adding it to
  both, because it lands after Slice 13 and Slice 14 rather than before them.

**Out of scope:** persistence across walks; reordering; queueing anything that wasn't triggered by
proximity.

**Acceptance:** Queueing from a prompt plays nothing and adds one entry. Walking into two
overlapping radii yields one prompt and one queued entry, not two prompts and not one lost story.
Playing from the queue removes it. Ending walking mode empties it. Unit tests on ordering,
de-duplication, and the busy-coordinator path.

**Notes:** This is the slice that answers a question the codebase has been carrying since Slice 3 —
the `ponytail:` comment in `CoreLocationProximityEngine` deferred queueing to "the audio service in
Slice 2" and it never happened. It belongs to the coordinator, not the player.

---

### Slice 12 — Relative direction
**Owner:** Kean · **Branch:** `feature/relative-direction` · **Est:** 2 days

**Goal:** *"on your left"*, never *"to the north-east"*.

**In scope:**
- `Services/Location/RelativeDirection.swift` — a pure function, no Core Location import, in the
  `ProximityEvaluator` mould: user coordinate + travel direction + site coordinate → phrase.
- Four buckets, ±45° each, in her words: `"just ahead"`, `"on your left"`, `"on your right"`,
  `"behind you"`.
- **Which way is she facing:** prefer `CLLocation.course` (GPS direction of travel) when speed is
  above a walking threshold and course accuracy is valid; fall back to `CLHeading.trueHeading`;
  if neither is trustworthy, **return nil and omit the direction from the phrase entirely.**
- Feed the phrase into Slice 11's prompt and expose it for Slice 14's UI.

**Out of scope:** gating triggers on heading (that's still N2, still flagged off). Direction affects
what we *say*, never whether we speak.

**Acceptance:** Unit tests on the pure function including 0°/360° wraparound, all four buckets, and
the low-confidence case returning nil. On a real device walking past a site, the spoken side matches
reality — including with the phone in a pocket, which is the case that fails if you use the compass
alone.

**Notes:** Her phone is in her pocket, so `trueHeading` reads wherever the pocket faces, not where
she's walking. A compass-only version demos fine on a desk and lies on the street. Course first.

---

### Slice 13 — Notification answer path
**Owner:** Nanda · **Branch:** `feature/consent-notifications` · **Est:** 3 days
**Depends on:** Slice 11's coordinator interface (see §5).

**Goal:** The same question, answerable from the lock screen. Supersedes old Slice 4.5.

**In scope:**
- Real `NotificationService` implementation replacing the empty protocol: authorization request,
  a `UNNotificationCategory` with **Play now** and **Dismiss** actions, body = site name +
  direction + story title. The third action, **Add to queue**, is added by Slice 11.5, which lands
  after this one — build the category so a third action is a one-line addition.
- Both actions resolve the **same coordinator state** as the stem press — `accept(promptID:)` /
  `decline(promptID:)`. Answering twice (stem then notification) must be a no-op, not a double play.
- Withdraw the delivered notification when the prompt is answered elsewhere or times out.
- One notification per prompt. No second notification when the story starts.

**Out of scope:** transcript in the notification body; Watch.

**Acceptance:** App backgrounded, screen locked, walking into a site posts one notification; Play
plays the story, Skip stays silent and the notification disappears; answering by stem first removes
the notification without playing twice. Device test notes in the PR.

**Notes:** `promptID` exists precisely so a stale notification from a previous site can't resolve the
current prompt — check it, don't assume.

---

### Slice 14 — Now screen
**Owner:** Nanda · **Branch:** `feature/now-screen` · **Est:** 4 days

**Goal:** Build the real home tab. Supersedes old Slice 5, reshaped by J1 and J3. This is also the
answer to her *"I just open maps and want to know where I am"* — position first, no route planning.

**In scope:**
- **Status line:** ambient state — "Listening for nearby stories" / "Nothing nearby yet."
- **Nearest-site teaser:** name, distance, and direction phrase — *"Pura Maospahit · 80m · on your
  left."* Distance-only until Slice 12 lands.
- **Walking mode switch**, the primary control on this screen — plus the honest permission state
  under it ("listening in the background" / "listening only while the app is open"). See Slice 11a.
- **Prompt state, mirrored on screen:** when the coordinator is `prompting`, show the site and two
  large targets, Play now and Dismiss, resolving the same prompt as the stem and the notification.
  This is the fallback for anyone not wearing AirPods. Slice 11.5 adds the third target and the
  queue list below it.
- **Now card:** current story, large play/pause, `Transcript ▾` disclosure, **collapsed by default**.
- **Today's walk feed** from the existing `HistoryStore`, reusing `TriggerEventRow`.
- Keep the speed menu — it already writes through to `SettingsStore` correctly. **The auto-play chip
  is gone**; walking mode takes its place. Slice 11 removes it.
- VoiceOver labels and Dynamic Type on everything. Non-negotiable per AGENTS.md.

**Out of scope:** map (done, Slice 6), history persistence (done, Slice 8).

**Acceptance:** Triggering a story moves the screen through prompt → playing → feed entry;
transcript expands on demand; on-screen Play resolves the same prompt as the stem; teaser shows the
nearest site with direction when idle. VoiceOver pass on the whole screen.

**Notes:** Transcript stays a fallback — do not let text become the primary path. Play targets stay
thumb-sized; she is walking.

---

### Slice 15 — Chunked narration
**Owner:** Nanda · **Branch:** `feature/story-chapters` · **Est:** 3 days + content
**Depends on:** Slice 11's coordinator. **Blocked on content — see §6.**

**Goal:** A short version first, more only if she asks.

**In scope:**
- **No new model.** `Site.stories` becomes an ordered chapter list. Add one field, `chapterIndex:
  Int`, to `Story` and to the content pack JSON — SwiftData does not guarantee relationship order,
  so the index has to be explicit.
- Content pack: chapter 1 ≈ 40s hook, chapter 2 ≈ 60–90s depth, for the 8 real sites.
- Coordinator gains `offeringMore`: when a chapter ends and a next one exists, speak *"there's more
  to this one — press play"* and reuse the identical answer paths and timeout.
- **Never auto-chain.** Every chapter after the first is consented to separately.

**Out of scope:** more than two chapters per site; per-chapter transcripts in the UI (the full
transcript stays on chapter 1).

**Acceptance:** A two-chapter site plays chapter 1, offers more, and stays silent on no answer.
Saying yes plays chapter 2. A one-chapter site ends cleanly with no offer. Works offline.

**Notes:** This keeps every stop under her 2-minute ceiling *by default*, and lets her exceed it
only by actively choosing to.

---

### Slice 16 — Interest modes *(stretch — cut this first)*
**Owner:** whoever is free in week 2 · **Branch:** `feature/interest-modes` · **Est:** 2 days

**Goal:** Joe's foodie / shopping / cultural framing, at code cost only.

**In scope:** an `interests: [String]` array per site in the content pack; a multi-select in
Settings; `ProximityEvaluator` filters candidates by selected interests. **No new audio** — this
tags what already exists (Pasar Badung → food, Park 23 → shopping, temples → cultural).

**Out of scope:** interest-specific *narration* variants. That is 13 sites × 4 modes of recording
and is not a two-week feature.

**Acceptance:** Deselecting "cultural" stops temple stories from triggering; selecting nothing
behaves as selecting everything. Preference persists.

**Notes:** This is the designated slip absorber. If any of 10–15 runs long, this is what gets cut,
and nothing else depends on it.

---

## 5. Dependencies and the one coordination risk

```
Slice 10 (audio) ─── start immediately, but see the file collision below
Slice 14 (Now)   ─── independent, start immediately
Slice 11 (consent + walking mode) ──┬── Slice 11.5 (queue)
                                    ├── Slice 12 (direction) → feeds 11's phrase and 14's teaser
                                    ├── Slice 13 (notifications)
                                    └── Slice 15 (chapters)
Slice 16 ─── independent, stretch
```

**Risk 1 — the shared interface.** Kean and Nanda both need `NarrationCoordinator` and only Kean is
building it. Kean's Slice 11 also rewires `AppEnvironment`, which everyone touches.

**The fix — do this on day 1, before anything else:** Kean opens one small PR containing *only* the
`NarrationCoordinator` protocol, the `NarrationState` enum, `PendingPrompt`, and
`MockNarrationCoordinator`, wired into `AppEnvironment`. Merge it immediately. Slices 13, 14 and 15
branch off that and develop against the mock while the real implementation is still being written.
Without this, Nanda is blocked for a week or, worse, invents her own version and collides at merge.

**Risk 2 — two people editing `AVAudioPlayerService.swift`.** Slice 10 restructures its teardown
paths; Slice 11 adds `onPlaybackFinished` to the same file and protocol. These were listed as
independent and are not. Tami's Slice 10 is one day and lands first — Kean rebases onto it rather
than the reverse, since the callback is one line inside the `endPlayback()` Slice 10 creates.

**Risk 3 — walking mode changes a key everyone reads.** `AppConfig.backgroundTriggeringKey` is read
straight from `UserDefaults` in `CooltourApp.init`, `CoreLocationProximityEngine`, and
`SettingsStore`. Renaming it to `walkingModeKey` is mechanical but touches three files outside
`Services/Narration/`. It rides in the day-1 interface PR so nobody rebases onto it twice.

---

## 6. Content is the critical path, and it has no owner yet

Slice 15 needs **8 new chapter-2 recordings**. AGENTS.md already says content, not code, is the
critical path for this app. Assign a name to this on day 1 — writing plus recording plus export is
not a day of work, and Slice 15 ships as silence without it.

Slice 12 also needs the four direction phrases reviewed by whoever owns narration voice, so the
synthesized prompt doesn't clash tonally with the produced audio.

---

## 7. Two-week schedule

| | Week 1 | Week 2 |
|---|---|---|
| **Kean** | Day 1: coordinator interface PR + walking-mode key rename (merge same day). Then **Slice 11** — walking mode, consent gate, no direction phrase yet. | **Slice 12** — relative direction (2d), then **Slice 11.5** — queue (2d). |
| **Tami** | **Slice 10** (day 1) — audio session repair. Lands before Kean touches the same file. | Support review / **Slice 16** stretch if green. |
| **Nanda** | **Slice 14** — Now screen, against the mock coordinator. Start **Slice 13** once interface lands. | Finish **Slice 13** (device-test on locked screen), then **Slice 15** once content lands. |
| **Content** | Write + record 8 chapter-2 narrations. | Export, add to pack, review direction phrases. |
| **Stretch** | — | **Slice 16** — realistically cut; see below. |

**Slice 16 is now almost certainly cut.** Adding Slice 11.5 fills Kean's week 2, and Slice 16 was
always the designated slip absorber. It is being spent deliberately rather than lost to overrun,
which is the difference between a plan and a wish. Nothing depends on it.

**Demo state at the end of week 1:** she turns on walking mode, walks, and a story asks before it
speaks — answered from the AirPod stem, hands never leaving her pockets. That alone is the finding.
Everything in week 2 makes it good rather than making it exist.

---

## 8. Definition of done for this phase

- [ ] Nothing plays unless she said yes. There is no mode that bypasses the ask.
- [ ] Walking mode is the one switch: on means listening, including after the app is killed; off
      means no wakes, no background session, no geofences, and the UI says so honestly.
- [ ] A trigger speaks a prompt and plays nothing until answered — stem, notification, or screen.
- [ ] No answer means silence, recorded as `timedOut`, and no second ask on the same entry.
- [ ] A story she queues waits until she asks for it, and never narrates a place she has left.
- [ ] Prompts say "on your left", never a compass bearing, and say nothing about direction when the
      direction isn't trustworthy.
- [ ] Her music pauses for narration and resumes afterwards, including after a call and after an
      AirPod is pulled.
- [ ] Stories arrive in chapters; chapter 2 requires a second yes.
- [ ] The Now screen shows where she is, what's nearest, which way it is, and what just played.
- [ ] Every new screen passes VoiceOver and Dynamic Type.
- [ ] The whole loop still runs in airplane mode.
