# AGENTS.md

Guidelines for AI agents and human contributors working in this repo.
Read this before touching anything. The full build spec lives in
[`documents/InitialCooltour.md`](documents/InitialCooltour.md) — this file is the working
agreement, not the spec.

---

## 1. Repo guideline

### Background

**Cooltour** (app codename *Nyasar*, placeholder) is a free-roam, **audio-first iOS app**
that plays the story behind a cultural site **the moment the user is physically standing
near it** — no route planning, no searching, no need to look at the screen.

Built by team Cooltour at the **Apple Developer Academy**, as a human-centered design
project inspired by **Kultara**, a Bali-based social enterprise running community walking
tours. MVP content is city-first (Denpasar), seeded from Kultara guide storytelling.

The gap it closes, validated across five stakeholder/user interviews: solo travelers think
*"why is this like this?"* only **after** they've already walked away. By then there's no
one to ask. Cooltour answers while they're still in front of it.

### Objectives

1. **Trigger the right story at the right place, in real time.** Proximity-triggered
   content is the core innovation — not route-building.
2. **Stay screen-free by default.** Audio is the primary channel; the screen is a
   fallback and orientation surface.
3. **Make stories stick.** Narrative and emotional, not encyclopedia bullet points.
4. **Work offline.** A walk must not break because the signal dropped.

### Product principles

Every change is tested against these. let developer know if any is violated, even if it
compiles.

- **The attention test** — *does this pull the user's attention onto the device, or push it
  back out onto the city?* If it pulls attention to the screen, it's wrong or it's a fallback.
- **Silence on low confidence** — if proximity/matching confidence is below threshold, play
  **nothing**. A wrong story at the wrong place destroys trust faster than silence does.
- **Offline-first** — no runtime network dependency in the core loop. No runtime AI or
  voice-generation calls; audio is pre-produced and bundled.
- **Privacy** — location stays on-device. No account, no server, no location upload in MVP.

### Explicit non-goals (MVP)

No route-builder/itinerary planner · no traveler-to-traveler social matching · no
remote/rural content · no account system or login · no AR.

### Repo layout

```
Cooltour/
├── App/          entry point, AppConfig, AppEnvironment (DI)
├── Services/     Location/ Audio/ Content/ Notifications/ — protocol-first, injectable
├── Features/     Now/ Map/ History/ Settings/ — one folder per tab
├── Models/       (not yet created — arrives in Slice 1)
│                 SwiftData models: Site, Story, Walk, TriggerEvent
├── Shared/       (not yet created) reusable UI, extensions, design tokens
└── Resources/    (not yet created — arrives in Slice 1)
                  bundled content pack (JSON + audio)
documents/        build plan and design research
```

Only `App/`, `Services/`, and `Features/` exist today (Slice 0 is done). The rest is the
target shape — create each folder in the slice that needs it, don't scaffold them early.
A unit test target and the sample `.gpx` route are likewise not in the project yet; they
land with the slices that need them (see §4).

**Architecture:** MVVM, feature-foldered. `ProximityEngine`, `AudioPlayerService`,
`ContentStore`, and `NotificationService` stay as separate services **behind protocols**
so they can be tested, mocked, and reused by the future Apple Watch target. Do not
collapse them into views.

**Brand name lives in exactly one place:** `AppConfig.appName` is the single source of truth
in code. Never hardcode the app name anywhere else. The final name is undecided —
`AppConfig` currently reads `"Cooltour"` (the team name), while the README pitches
**Nyasar** as the candidate app name. That mismatch is expected until the team settles it;
resolve it by changing `AppConfig.appName`, not by scattering the new name through the code.

---

## 2. GitHub guideline

### The rule that matters most

> **Never `commit`, `push`, or open a PR unless a human explicitly tells you to in that
> message. Never merge to `main`.**

Not "when the work looks done." Not "when tests pass." Only on an explicit instruction.
Leave changes in the working tree and report what you changed. Merging is done **manually
by a teammate who has reviewed the code** — an agent never merges its own work, and never
approves a PR.

`main` is protected by convention: no direct commits, no direct pushes, ever.

### Branching

Every member and every agent works on their own branch off `main`. Never build directly on
`main`.

| Prefix | Use for |
|---|---|
| `feature/` | new functionality — `feature/proximity-engine` |
| `bugfix/` | fixing broken behavior — `bugfix/audio-session-interrupt` |
| `test/` | test-only work — `test/proximity-debounce` |
| `refactor/` | restructuring, no behavior change — `refactor/content-store-protocol` |
| `docs/` | documentation and assets — `docs/agents-guidelines` |
| `chore/` | tooling, config, project file housekeeping |

Naming: lowercase, kebab-case, short and descriptive. One branch per unit of work — a
branch that does three unrelated things is three branches.

```bash
git checkout main && git pull && git checkout -b feature/short-description
```

### Commit messages

Short, descriptive, imperative. Mention the changed area first when it helps — a component
prefix is welcome but not mandatory.

```
Now: add transcript disclosure to now-playing card
Fix trigger flapping when re-entering a site radius
ContentStore: seed idempotently off contentPackVersion
```

Keep commits **focused** — one logical change each. Don't bundle a refactor into a bugfix.

### Pull requests

A PR should include:

- **Summary** — concise, what changed and why.
- **Test notes** — what you ran, what passed.
- **Manual device test notes** — when relevant (anything touching location, audio,
  notifications, or background behavior *must* be tested on a real device and say so).
- **Linked issue / task context** — see below.
- **Screenshots or screen recordings** — required for any UI or asset change.

PRs are reviewed by a teammate. Reviewers merge; authors don't.

### Linking context to a PR

Every PR says what it belongs to. Two cases:

**Planned work** — reference the slice number from
[`documents/InitialCooltour.md`](documents/InitialCooltour.md):

> `Slice 3 — Proximity engine (foreground)`

The plan doc already carries the scope and acceptance criteria, so don't duplicate it into
an issue.

**Bugs and unplanned work** — file a GitHub Issue first, then close it from the PR
description with GitHub's linking keyword:

> `Closes #14`

On merge to `main` that automatically closes issue #14 and links the two permanently, so
the "why" behind a change survives after the branch is deleted.

- Keywords: `closes` / `fixes` / `resolves` (and their past tenses). All equivalent.
- The `#` is required — `Closes 14` does nothing.
- One keyword per issue: `Closes #14, closes #15`, not `Closes #14, #15`.
- Only auto-closes when merged into the default branch (`main`).
- Use `Refs #14` when a PR relates to an issue but doesn't finish it.

This is the one PR field a reviewer can't reconstruct later — screenshots and test notes
can be added after the fact; the reason a change exists can't.

---

## 3. Project build context

| | |
|---|---|
| IDE | **Xcode 26** |
| Language | **Swift 6** (strict concurrency on — respect it, don't silence it) |
| Minimum target | **iOS 26.5**, iPhone first |
| Next platform | **Apple Watch** — watchOS companion is planned post-iPhone-MVP |
| UI | SwiftUI, SwiftUI app lifecycle |
| Persistence | SwiftData |
| Location | Core Location (`CLMonitor` region monitoring for background) |
| Audio | AVFoundation baseline; PHASE spatial audio later, behind `AppConfig.usePHASE` |
| Notifications | UserNotifications (local only, no push) |
| Maps | MapKit (SwiftUI `Map`) |

Watch companion work lives in [`documents/WatchSlices.md`](documents/WatchSlices.md).
Keep anything shared — models, service protocols, playback and proximity logic — free
of iOS-only and UI-only assumptions. The Watch never owns story audio or the
proximity brain; it talks to the phone through WatchConnectivity payloads.

New capabilities go behind flags in `AppConfig` (`autoPlayDefault`, `usePHASE`,
`headingRefinement`) so they can ship dark.

### Coding style & naming convention

Follow the Swift API Design Guidelines. Specifics for this repo:

- **Naming:** `UpperCamelCase` for types, `lowerCamelCase` for everything else. Views end
  in `View` (`NowView`), services end in `Service` or name the role (`ProximityEngine`),
  mock implementations are prefixed `Mock` (`MockContentStore`).
- **Units in names.** `triggerRadiusMeters`, `durationSeconds`, `maxLocationAccuracyMeters` —
  never a bare `radius` or `duration`.
- **One primary type per file**, file named after it. Small related helpers may share it.
- **Protocol-first services.** Every service is a protocol with a real implementation and a
  `Mock` for previews and tests.
- **Concurrency:** the project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and
  `SWIFT_APPROACHABLE_CONCURRENCY = YES`, so **everything is `@MainActor` by default** —
  you don't annotate views or view models, you get it for free. The work is the *opposite*:
  anything that must run off the main actor (Core Location callbacks, audio rendering, file
  and JSON loading) has to **explicitly opt out** with `nonisolated`, its own `actor`, or a
  detached task, and hand results back to the main actor. Fix data-race warnings properly;
  don't reach for `@unchecked Sendable` or `nonisolated(unsafe)` to make them go away.
- **Formatting:** 4-space indent, Xcode default. Trailing closures for SwiftUI builders.
  Prefer early `guard` over nesting.
- **Comments** explain *why*, not *what*. See `AppConfig.maxLocationAccuracyMeters` for the
  house style: one line, explains the rationale, not the syntax.
- **Accessibility is not optional.** VoiceOver labels and Dynamic Type support on every
  screen — this is an audio app for people who aren't looking at the screen.
- **No speculative abstraction.** Don't add a protocol, manager, or config knob for a case
  that doesn't exist yet. Build the slice in front of you.

---

## 4. Testing guideline

- **Framework: Swift Testing** (`import Testing`, `@Test`, `#expect`). Not XCTest — do not
  add new XCTest cases.
- **Run in the iOS Simulator** for the default loop; keep tests device-independent where
  possible.
- **Mocks over the real world.** Services are protocol-first precisely so tests inject
  `Mock*` implementations instead of waiting on GPS or audio hardware.
- **Location testing:** use Xcode **GPX route simulation**. Keep a sample `.gpx` in the repo
  that walks through the seeded sites.
- **Always test on a real device** — and say so in the PR — for anything touching location,
  background triggering, notifications, audio session behavior, or battery.
- **Test the nasty cases, not the happy path.** Specifically: trigger debounce and
  re-arm/flapping at a radius boundary, low-accuracy fixes producing *no* trigger, audio
  interruptions (incoming call) and route changes (AirPods removed), permission denied and
  degraded, missing audio asset, and the full loop **in airplane mode**.
- Non-trivial logic ships with at least one test that fails if the logic breaks. Trivial
  one-liners don't need one.

---

## 5. State management (Observation, iOS 26)

Use the **Observation framework**. This is the default and there's no legacy to preserve —
the project starts here.

- **`@Observable`** on model and view-model classes. Do **not** use `ObservableObject`,
  `@Published`, `@StateObject`, or `@ObservedObject` unless a dependency genuinely forces it
  (say so in the PR if it does).
- **`@State`** in the view that *owns* the observable object's lifetime.
- **Plain `let`/`var` property** in views that merely *read* an observable passed in — no
  wrapper needed; Observation tracks the properties actually read in `body`.
- **`@Bindable`** when a view needs two-way bindings (`$model.property`) into an
  `@Observable` object it doesn't own.
- **`@Environment(AppEnvironment.self)`** to reach shared services. `AppEnvironment` is the
  DI container — it's injected once at the root via `.environment(...)` and holds
  `content`, `audio`, `proximity`, and `notifications`. Add a new shared service there
  rather than inventing a second injection path or a singleton.
- **No singletons.** No `.shared` service instances. Everything comes through
  `AppEnvironment` so it can be swapped for a mock in previews and tests.
- **One source of truth per piece of state.** User preferences live in one place
  (`@AppStorage`/`SettingsStore`); the Now-screen quick controls and the Settings screen
  read and write that same source — never a second copy kept in sync by hand.
- **Keep observable state small and behind intent-named methods** (`play(story:)`,
  `setRate(_:)`), not a bag of public mutable properties that views poke directly.
- **Previews use mocks:** `#Preview { SomeView().environment(AppEnvironment()) }` — the
  default `AppEnvironment()` init already wires up every `Mock*` service.
