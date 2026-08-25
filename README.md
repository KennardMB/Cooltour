# Walkaby

**Wander freely. Let the city tell you why.**

Walkaby is a free-roam, audio-first iOS app that surfaces the story behind a place the moment you're standing in front of it — no planning, no searching, no screen required.

Built by **Cooltour**, a team at the Apple Developer Academy, as a human-centered design project inspired by **Kultara**, a Bali-based social enterprise running community walking tours connecting travelers with local artisans, guides, and communities.

The product name in code is `AppConfig.appName` (`Walkaby`). This repository and Xcode target still use the team codename *Cooltour*.

---

## The problem

Solo travelers who stumble on something culturally interesting — a shrine, a market stall, an unfamiliar building — usually have the "why does this exist?" question occur to them *after* they've already walked away. By then there's no one left to ask, and searching for it later rarely surfaces a real answer. In the moment, the only fallback is asking a local, which carries language barriers, social hesitation, and scam risk.

Validated across five interviews with solo travelers and Kultara's own guides and co-founder, this in-the-moment information gap was the single most consistent finding across the research.

## The idea

Walkaby listens for where you are and what you're near, asks whether you want a story when you approach a tagged site, then plays short, story-driven narration exactly while you're in front of the thing that sparked your curiosity. Audio keeps your eyes up and on the place, not on the screen.

**Design principle:** every feature is tested against one question — *does this pull the user's attention onto the device, or push it back out onto the city?*

---

## MVP scope

| Area | What it does today |
|---|---|
| **Proximity detection** | GPS via Core Location (`CLLocationUpdate`, `CLMonitor` geofences). Triggers only on trusted fixes (≤ 35 m accuracy). Re-arm logic prevents repeat fires at radius boundaries. |
| **Consent gate** | Stories never auto-play. A spoken prompt + notification asks play / queue / dismiss before narration starts. |
| **Story playback** | Bundled pre-recorded audio (AVFoundation). Playback speed, ±10 s skip, lock-screen / AirPods controls, transcript fallback. |
| **Now experience** | Start exploration, wandering state, site discovery prompt, full-screen sites player (carousel, scrubber, queue, transcript sheet). |
| **Map** | Seeded sites + live user position; manual play from site detail. |
| **Exploration** | Persisted walk sessions and trigger history with per-story outcomes. |
| **Settings** | Walking mode, playback speed, English / Indonesian UI and audio language, permissions guidance. |
| **Offline-first** | Content packs (JSON + audio) bundled in-app; no runtime network or AI calls in the core loop. |

### Content packs (seeded)

| Pack | Region |
|---|---|
| `denpasar` | Central Denpasar sites |
| `renon` | Renon district sites |

Additional pack JSON (e.g. Sanur) may exist in `Resources/` before it is wired into `AppConfig.contentPackNames`.

### Post-MVP / not wired yet

- Apple Watch companion
- PHASE spatial audio (`AppConfig.usePHASE` is off)
- Heading-based trigger refinement (`AppConfig.headingRefinement` is off)
- WeatherKit / time-of-day narration selection
- Route builder, social matching, accounts, AR

---

## Platform & stack

| | |
|---|---|
| IDE | Xcode 26 |
| Language | Swift 6 (strict concurrency) |
| Minimum target | iOS 26.5, iPhone first |
| UI | SwiftUI, Observation (`@Observable`) |
| Persistence | SwiftData (sites, stories, walks, trigger events) |
| Location | Core Location — live updates + `CLMonitor` background wakes |
| Audio | AVFoundation story playback; on-device TTS for consent prompts only |
| Notifications | UserNotifications (local, actionable) |
| Maps | MapKit (SwiftUI `Map`) |
| Tests | Swift Testing (`CooltourTests`) |

**Silence-on-low-confidence:** if proximity or GPS confidence is below threshold, the app stays quiet rather than guessing.

Architecture details: [`documents/Architecture.md`](documents/Architecture.md). Build slices and acceptance criteria: [`documents/InitialCooltour.md`](documents/InitialCooltour.md). Contributor rules: [`AGENTS.md`](AGENTS.md).

---

## Design research

This project follows a full human-centered design process: stakeholder interviews (supply-side: Kultara guides/co-founder; demand-side: solo travelers), affinity mapping, persona development and validation, and iterative concept testing against a fixed evaluation framework.

Design tokens and Figma alignment: [`docs/DesignSystem.md`](docs/DesignSystem.md).

**Core persona — Sam, "The Organic Wanderer":** culture-willing but access-gated, not culture-obsessed. Curiosity is reactive and in-the-moment; the product's job is to lower the cost of engaging with culture at the exact moment curiosity strikes.

---

## Status

**Active MVP development** — core walk loop is implemented and under UI polish.

| Slice area | State |
|---|---|
| Project skeleton, DI, config | Done |
| Content store + bundled packs | Done (Denpasar, Renon) |
| Audio playback + speed / skip | Done |
| Proximity engine (foreground + background) | Done |
| Local notifications + consent narration | Done |
| Now screen (Figma FE phase 1) | In progress — idle, wandering, prompt, sites player, profile |
| Map tab | Done (baseline) |
| Exploration / walk history | Done (baseline) |
| Settings + localization | Done (baseline) |
| Offline hardening & MVP exit criteria | Partial — device testing ongoing |

Debug surfaces (`Proximity`, content pack) ship for acceptance testing; simulate-approach picker available on the Now wandering screen during development.

---

## Team

Cooltour — Apple Developer Academy.

## License

TBD
