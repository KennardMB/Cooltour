# Nyasar

**Wander freely. Let the city tell you why.**

Nyasar *(Indonesian, informal: "to wander off, to get pleasantly lost")* is a free-roam, audio-first iOS app that surfaces the story behind a place the moment you're standing in front of it — no planning, no searching, no screen required.

Built by **Cooltour**, a team at the Apple Developer Academy, as a human-centered design project inspired by **Kultara**, a Bali-based social enterprise running community walking tours connecting travelers with local artisans, guides, and communities.

> Rename freely — this is a placeholder pending final team decision.

---

## The problem

Solo travelers who stumble on something culturally interesting — a shrine, a market stall, an unfamiliar building — usually have the "why does this exist?" question occur to them *after* they've already walked away. By then there's no one left to ask, and searching for it later rarely surfaces a real answer. In the moment, the only fallback is asking a local, which carries language barriers, social hesitation, and scam risk.

Validated across five interviews with solo travelers and Kultara's own guides and co-founder, this in-the-moment information gap was the single most consistent finding across the research.

## The idea

Nyasar listens for where you are and what you're near, and plays a short, story-driven narration exactly when you're in front of the thing that sparked your curiosity — not before, not after. Audio keeps your eyes up and on the place, not on the screen.

**Design principle:** every feature is tested against one question — *does this pull the user's attention onto the device, or push it back out onto the city?*

---

## MVP Scope

| Feature | Description |
|---|---|
| **Proximity detection** | Locates the user in the world using GPS, compass heading, and dwell time to know when they're near or facing a tagged cultural site |
| **Story trigger** | Plays narrated content automatically as the user approaches a site, or on manual tap — user-configurable |
| **Playback speed control** | Adjustable narration speed |
| **Notification + transcript** | Tappable iPhone notification plays the story; expandable transcript available as a fallback (not the primary mode) |
| **Site content database** | Structured story + location content per site, written as narrative — not encyclopedia-style facts |
| **Map integration** | Secondary tab showing tagged sites and the user's live position; supports orientation and browsing, not the core experience |

## Nice to Have (Post-MVP)

- **Walk history** — a persisted log of stories triggered on past walks
- **Photo capture per site** — user photos replace the default map pin icon for that site; paired with a lightweight journal
- **Sharing** — share photos and completed routes

## What Nyasar deliberately isn't

- **Not a route-builder.** The core innovation is triggering content by *where you are and what you're facing*, not planning a path in advance.
- **Not a travel-buddy matcher.** Solo travelers seek connection with locals as a doorway into culture, not social matching with other travelers — this space was considered and deliberately rejected.
- **Not remote/rural at MVP.** Content quality depends on seedable, story-rich data. MVP scope is intentionally city-first (Denpasar), where content can realistically be produced and Kultara's own operating ground provides both seed content and a test channel.

---

## Platform & Stack

Designed Apple-native and screen-free by default:

- **Location & motion:** Core Location (GPS + compass heading), dwell-time logic for trigger confidence
- **Spatial audio:** Apple PHASE
- **Context-aware narration:** WeatherKit (time-of-day / condition matching)
- **Voice content:** ElevenLabs for narration synthesis; RAG-grounded generation anchored to real sightlines and verified local sourcing
- **Wearables:** AirPods (head-orientation awareness), Apple Watch (interactable notifications — planned post-iPhone MVP)
- **Offline-first:** content bundled/pre-downloaded so playback works without a live connection; GPS functions offline

**Silence-on-low-confidence principle:** if the system isn't confident about a match, it stays quiet rather than guessing — protecting trust over completeness.

---

## Design Research

This project follows a full human-centered design process: stakeholder interviews (supply-side: Kultara guides/co-founder; demand-side: solo travelers), affinity mapping, persona development and validation, and iterative concept testing against a fixed evaluation framework.

Full research documentation, interview analysis, and persona rationale live in `/docs` (or link to your research repo/Notion here).

**Core persona — Sam, "The Organic Wanderer":** culture-willing but access-gated, not culture-obsessed. Curiosity is reactive and in-the-moment; the product's job is to lower the cost of engaging with culture at the exact moment curiosity strikes.

---

## Status

Pre-development — MVP scope finalized, entering design/build phase.

## Team

Cooltour — Apple Developer Academy. 
## License

TBD

