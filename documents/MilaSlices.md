# MilaSlices.md
### Post-User-Test Development Plan — Slices 10–16

**Source:** user test with Mila (Apple Developer Academy mentor, solo traveler), Aug 2026.
**Companion to:** [`InitialCooltour.md`](InitialCooltour.md) — that document is still the spec for
everything it covers. This one adds slices 10–16 and supersedes two of its slices (see §3).
**Phase length:** 2 weeks. **Team:** Kean, Nanda, Tami.
**Status:** approved, ready to build.

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

The coordinator owns a state machine:

```
idle → prompting → playing → offeringMore → playing → … → idle
          ↓ (timeout, decline, or left radius)
        idle
```

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

Slices 0–4, 6, 7, 8 are done. Numbering continues at 10 to avoid colliding with the existing 9.

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

### Slice 11 — Approach prompt + consent gate ⭐ *demo centerpiece*
**Owner:** Kean · **Branch:** `feature/narration-coordinator` · **Est:** 4 days

**Goal:** *"You're approaching Pura Maospahit. Press play to hear it."* — and silence if she doesn't.

**In scope:**
- `Services/Narration/NarrationCoordinator.swift` — protocol + `@Observable` implementation, plus
  `MockNarrationCoordinator`. Holds `state: NarrationState`, `pendingSite`, `pendingPrompt`.
- `PromptVoice` protocol with one method, `speak(_ text: String)`. `SystemPromptVoice` wraps
  `AVSpeechSynthesizer`; `MockPromptVoice` records what it was asked to say, for tests.
- Answer path A: `MPRemoteCommandCenter.playCommand`, armed only while awaiting consent, so the
  AirPod stem answers without touching the phone. Populate `MPNowPlayingInfoCenter` so the lock
  screen shows what's pending.
- Timeout: `AppConfig.consentTimeoutSeconds = 20`. No answer → silence, logged as declined.
- Leaving the trigger radius mid-prompt cancels the prompt.
- One ask per site entry. Re-arming is already handled by `ProximityEvaluator`'s re-arm ring —
  reuse it, do not add a second cooldown.
- Rewire `AppEnvironment`: `proximity.onTrigger` now calls the coordinator, not `audio.play`.

**The `autoPlay` setting keeps its name and changes meaning — state this in the PR:**

| `autoPlay` | Before | After this slice |
|---|---|---|
| ON | story plays immediately | **spoken prompt, then plays on yes** |
| OFF | nothing happens | **no spoken prompt; notification only** (Slice 13) |

Auto-play OFF suppresses the *voice*, not the *state*: the coordinator still enters `prompting`, so
the notification and the on-screen Play/Skip have a live prompt to resolve. Only `PromptVoice` is
skipped.

**Out of scope:** the notification answer path (Slice 13), the on-screen prompt UI (Slice 14),
chapters (Slice 15). Direction in the prompt string is stubbed as `"nearby"` until Slice 12 lands.

**Acceptance:** Simulating the GPX route with auto-play on, entering a radius speaks the prompt and
plays nothing until answered. Stem press plays the story. Twenty seconds of silence plays nothing
and logs a decline. Walking out mid-prompt cancels it. Unit tests cover: timeout, decline, accept,
double-answer idempotency, and cancel-on-exit — all against `MockAudioPlayerService` and
`MockPromptVoice`, no hardware.

**Notes:** Inject the timeout so tests don't wait 20 real seconds. This slice ships first because
it's the demo; it ships with a stubbed direction phrase rather than waiting on Slice 12.

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
  a `UNNotificationCategory` with **Play** and **Skip** actions, body = site name + direction +
  story title.
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
- **Prompt state, mirrored on screen:** when the coordinator is `prompting`, show the site and two
  large targets, Play and Skip, resolving the same prompt as the stem and the notification. This is
  the fallback for anyone not wearing AirPods.
- **Now card:** current story, large play/pause, `Transcript ▾` disclosure, **collapsed by default**.
- **Today's walk feed** from the existing `HistoryStore`, reusing `TriggerEventRow`.
- Keep the existing quick controls (auto-play chip, speed menu) — they already write through to
  `SettingsStore` correctly.
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
Slice 10 (audio) ─── independent, start immediately
Slice 14 (Now)   ─── independent, start immediately
Slice 11 (consent) ──┬── Slice 12 (direction)  → feeds 11's phrase and 14's teaser
                     ├── Slice 13 (notifications)
                     └── Slice 15 (chapters)
Slice 16 ─── independent, stretch
```

**The risk:** Kean and Nanda both need `NarrationCoordinator` and only Kean is building it. Kean's Slice 11
also rewires `AppEnvironment`, which everyone touches.

**The fix — do this on day 1, before anything else:** Kean opens one small PR containing *only* the
`NarrationCoordinator` protocol, the `NarrationState` enum, and `MockNarrationCoordinator`, wired
into `AppEnvironment`. Merge it immediately. Slices 13, 14 and 15 branch off that and develop
against the mock while the real implementation is still being written. Without this, Nanda
is blocked for a week or, worse, invents her own version and collides at merge.

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
| **Kean** | Day 1: coordinator interface PR (merge same day). Then **Slice 11** — consent gate, stubbed direction. | **Slice 12** — relative direction; wire the real phrase into 11 and hand it to 14. |
| **Tami** | **Slice 10** (day 1) — audio session repair. | Support review / **Slice 16** stretch if green. |
| **Nanda** | **Slice 14** — Now screen, against the mock coordinator. Start **Slice 13** once interface lands. | Finish **Slice 13** (device-test on locked screen), then **Slice 15** once content lands. |
| **Content** | Write + record 8 chapter-2 narrations. | Export, add to pack, review direction phrases. |
| **Stretch** | — | **Slice 16** if all of the above is green. |

**Demo state at the end of week 1:** a story asks before it speaks, and answers from the stem.
That alone is the finding. Everything in week 2 makes it good rather than making it exist.

---

## 8. Definition of done for this phase

- [ ] A trigger speaks a prompt and plays nothing until answered — stem, notification, or screen.
- [ ] No answer means silence, logged, and no second ask on the same entry.
- [ ] Prompts say "on your left", never a compass bearing, and say nothing about direction when the
      direction isn't trustworthy.
- [ ] Her music pauses for narration and resumes afterwards, including after a call and after an
      AirPod is pulled.
- [ ] Stories arrive in chapters; chapter 2 requires a second yes.
- [ ] The Now screen shows where she is, what's nearest, which way it is, and what just played.
- [ ] Every new screen passes VoiceOver and Dynamic Type.
- [ ] The whole loop still runs in airplane mode.
