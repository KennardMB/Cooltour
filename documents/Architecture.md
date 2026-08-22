# Cooltour Architecture

A map of the running iOS app: folders, files, frameworks, and the walk-to-story path.

This document describes **the code as it exists today**, not the aspirational stack in the README (PHASE, WeatherKit, heading). Those are planned, not wired. Product intent and slice history live in [`InitialCooltour.md`](InitialCooltour.md). Agent working rules live in [`AGENTS.md`](../AGENTS.md).

**Codename:** Nyasar (placeholder). The string that appears in UI and Now Playing is `AppConfig.appName` (`"Cooltour"`). Change that constant, not scattered literals.

---

## 1. What the app does

Cooltour is a **free-roam, audio-first** walking app. It does not plan a route. It listens to GPS, notices when you walk into a tagged cultural site in Denpasar, **asks** whether you want the story, then plays a pre-recorded narration.

The design test for every screen: *does this pull attention onto the phone, or push it back onto the city?* Audio is the primary channel. The screen is a fallback.

Three product rules that show up as code, not just comments:

1. **Silence on low confidence.** A GPS fix worse than 35 m accuracy triggers nothing (`ProximityEvaluator` + `AppConfig.maxLocationAccuracyMeters`).
2. **Consent before playback.** A site entering range never auto-plays. `ConsentNarrationCoordinator` prompts first.
3. **Offline-first.** Stories are bundled JSON + audio files. The one runtime voice is a short on-device TTS prompt (`AVSpeechSynthesizer`), not a network call.

---

## 2. Architecture pattern

**MVVM, feature-foldered, protocol-first services.**

Views do not own location, audio, or notifications. They read and call into services held by one dependency-injection container: `AppEnvironment`.

```
CooltourApp  (process start, SwiftData, production wiring)
     │
     ▼
AppEnvironment  (content, proximity, narration, audio, queue, notifications, settings, history)
     │
     ▼
RootView  (four tabs)
     ├── NowView
     ├── MapView
     ├── HistoryView
     └── SettingsView
```

Every shared service is a **protocol** plus:

| Role | Protocol | Production | Mock (previews / tests) |
|---|---|---|---|
| Sites & stories | `ContentStore` | `LocalContentStore` | same, in-memory |
| GPS / geofences | `ProximityEngine` | `CoreLocationProximityEngine` | `MockProximityEngine` |
| Consent gate | `NarrationCoordinator` | `ConsentNarrationCoordinator` | `MockNarrationCoordinator` |
| Story playback | `AudioPlayerService` | `AVAudioPlayerService` | `MockAudioPlayerService` |
| Later-list | `StoryQueue` | `WalkStoryQueue` | `MockStoryQueue` |
| Local notifications | `NotificationService` | `UNNotificationService` | `MockNotificationService` |
| Spoken prompt | `PromptVoice` | `SystemPromptVoice` | `MockPromptVoice` |
| AirPod stem | `ConsentRemoteControl` | `SystemConsentRemoteControl` | `MockConsentRemoteControl` |

`AppEnvironment()` with no arguments already wires every mock. That is why SwiftUI `#Preview` blocks can run without GPS or a real audio session.

State uses the **Observation** framework (`@Observable`), not `ObservableObject`. Swift 6 defaults every type to `@MainActor`; anything that must leave the main actor (file load, Core Location streams) opts out explicitly.

---

## 3. Folder map

```
Cooltour/
├── CooltourApp.swift          App entry (@main)
├── RootView.swift             Tab bar + walking-mode start/stop
├── Localizable.xcstrings      String Catalog (UI chrome)
├── Info.plist                 Background modes: audio + location
├── App/                       Config + DI
├── Models/                    SwiftData + content-pack JSON shape
├── Services/                  Protocol-first engines (no UI)
│   ├── Location/              GPS, geofences, trigger decision
│   ├── Narration/             Consent, TTS prompt, queue
│   ├── Audio/                 Story file playback
│   ├── Content/               Seed pack → SwiftData
│   ├── Notifications/         Local prompt banners
│   ├── History/               Walks + trigger log
│   └── Settings/              UserDefaults preferences
├── Features/                  One folder per tab (plus Debug)
│   ├── Now/
│   ├── Map/
│   ├── History/
│   ├── Settings/
│   └── Debug/
├── Shared/                    Reusable UI pieces
├── Resources/                 Bundled JSON packs
└── Assets.xcassets

CooltourTests/                 Swift Testing (not XCTest)
Testing/                       GPX route + helper scripts
documents/                     Specs and this architecture map
```

---

## 4. File-by-file

### 4.1 Process entry

| File | What it does |
|---|---|
| `Cooltour/CooltourApp.swift` | `@main` app. Creates the SwiftData `ModelContainer`, seeds the content pack, builds **production** services, injects `AppEnvironment`. If walking mode was already on (persisted in `UserDefaults`), it calls `proximity.start()` **here** — Core Location can relaunch a terminated app into the background, where no view appears. |
| `Cooltour/RootView.swift` | Four-tab `TabView`. Observes `settings.walkingMode` and calls `proximity.start()` / `stop()`. Observes `proximity.isListening` and starts/stops a `Walk` in history. Applies the in-app locale. |
| `Cooltour/App/AppConfig.swift` | Named constants: app name, pack name (`"denpasar"`), trigger/accuracy/re-arm numbers, walking-mode `UserDefaults` key, dismiss countdown. Feature flags `usePHASE` and `headingRefinement` exist but are **off**. |
| `Cooltour/App/AppEnvironment.swift` | The DI bag. Wires `proximity.onTrigger` → `narration.handleTrigger`, `proximity.onEventLogged` → `history.addEvent`, notification answers → `accept`/`dismiss`/`queue`, and prompt outcomes → `history.resolveOutcome`. |

### 4.2 Models (`Cooltour/Models/`)

SwiftData models persist; `ContentPack` is only the JSON decoder shape.

| File | What it is |
|---|---|
| `Site.swift` | A place: slug, name, district, lat/lng, trigger radius, heading flag, stories. |
| `Story.swift` | A narration: titles, EN/ID audio asset names, transcripts, durations. `audioAssetName(for:)` returns `nil` if Indonesian was requested but not shipped — playback stays silent rather than falling back. |
| `Walk.swift` | One walking-mode session (`startedAt` / `endedAt`) plus its trigger events. |
| `TriggerEvent.swift` | One firing at one place/time, with a `PromptOutcome` stored as a `String` (`pending`, `played`, `dismissed`, `timedOut`, `queued`). |
| `ContentPack.swift` | Decodes `denpasar.json` / `renon.json`. Supports both a plain English string and `{ "en", "id" }` objects so older packs still load. |

### 4.3 Location (`Cooltour/Services/Location/`)

| File | What it does | Frameworks |
|---|---|---|
| `ProximityEngine.swift` | Protocol: `start()`, `stop()`, live fix, nearby sites, `onTrigger` / `onEventLogged`. Also `MockProximityEngine` and `simulateTrigger` for debug/previews. | Core Location (auth status type only) |
| **`CoreLocationProximityEngine.swift`** | **Production engine. This is what actually listens.** See [§6](#6-corelocationproximityengine--start-stop-frameworks). | **Core Location, UIKit, Foundation** |
| `ProximityEvaluator.swift` | Pure function: distances in, slugs that just entered radius out. Accuracy gate + re-arm hysteresis. No GPS types, so unit-testable. | Foundation |
| `ProximityEvent.swift` | Flat `Sendable` record of one firing. Decoupled from SwiftData so the engine never needs a `ModelContext`. | Foundation |

### 4.4 Narration (`Cooltour/Services/Narration/`)

Sits **between** proximity and audio: proximity decides *where*, the coordinator decides *whether / when*, the player decides *how*.

| File | What it does | Frameworks |
|---|---|---|
| `NarrationCoordinator.swift` | Protocol: `handleTrigger`, `accept`, `dismiss`, `queue`. | Foundation |
| `ConsentNarrationCoordinator.swift` | Production consent gate. Speaks the prompt, posts a notification, pauses the current story only for the spoken line, then play / queue / dismiss / timeout. | Observation, Foundation |
| `NarrationState.swift` | `.idle` / `.prompting` / `.playing`. | — |
| `PendingPrompt.swift` | Flat value the UI, notification, and Watch could all render without SwiftData. | Foundation |
| `ApproachPrompt.swift` | Builds the spoken sentence from site name + optional direction. | Foundation |
| `ConsentStrings.swift` | EN/ID copy for prompts, notifications, Now status. Used because in-app language override sits outside SwiftUI `Text`. | Foundation |
| `PromptOutcome.swift` | How a prompt resolved. | Foundation |
| `PromptVoice.swift` | Protocol to speak / stop the short question. | Foundation |
| `SystemPromptVoice.swift` | On-device TTS. | **AVFoundation** (`AVSpeechSynthesizer`) |
| `ConsentRemoteControl.swift` | Protocol: arm AirPod stem as “play now”, then disarm. | Foundation |
| `SystemConsentRemoteControl.swift` | Production stem / lock-screen play command. | **MediaPlayer** |
| `StoryQueue.swift` | Protocol for the walk-scoped later-list. | Foundation |
| `WalkStoryQueue.swift` | In-memory queue, de-duplicated by story slug, cleared when walking mode turns off. | Observation |
| `QueuedStory.swift` | List-row value type. | Foundation |
| `Mock*.swift` | Test/preview doubles. | — |

### 4.5 Audio (`Cooltour/Services/Audio/`)

| File | What it does | Frameworks |
|---|---|---|
| `AudioPlayerService.swift` | Protocol: play / pause / resume / stop / rate, plus `onPlaybackFinished`. | Foundation |
| `AVAudioPlayerService.swift` | Loads a bundled file, plays it, lock-screen Now Playing, interruption + route-change handling (phone call, AirPods removed). | **AVFoundation**, **MediaPlayer**, Observation |
| `MockAudioPlayerService.swift` | Preview/test player. | Observation |

Story audio is **pre-produced files** in the app bundle. The player never streams and never synthesizes narration.

### 4.6 Content, notifications, history, settings

| File | What it does | Frameworks |
|---|---|---|
| `Services/Content/ContentStore.swift` | `LocalContentStore`: loads `denpasar.json`, inserts `Site`/`Story` into SwiftData, caches `allSites()`. Re-seeds when the pack version changes. | SwiftData, Foundation |
| `Services/Notifications/NotificationService.swift` | Protocol + mock. | Observation |
| `Services/Notifications/UNNotificationService.swift` | Posts the approach banner with Play / Queue / Dismiss actions; routes taps back through `onAnswer`. | **UserNotifications** |
| `Services/History/HistoryStore.swift` | Starts/stops `Walk`s, logs pending triggers, resolves outcomes. | SwiftData |
| `Services/Settings/SettingsStore.swift` | Walking mode, playback speed, app language, audio language. Persisted in `UserDefaults`. Walking mode uses `AppConfig.walkingModeKey` so launch code can read it with no view. | Foundation, Observation |
| `Services/Settings/AppLanguagePreference.swift` | UI chrome: system / English / Indonesian. | Foundation |
| `Services/Settings/AudioLanguagePreference.swift` | Which recording to play: English or Indonesian. Independent of UI language. | Foundation |

### 4.7 Features (screens)

| File | Tab / role |
|---|---|
| `Features/Now/NowView.swift` | Home. Walking-mode toggle, status line, now-playing card, consent buttons, queue list, “simulate pura approach”. |
| `Features/Now/NowCard.swift` | Play/pause, progress, speed chips, transcript disclosure. No service access — callbacks only. |
| `Features/Now/TranscriptDisclosure.swift` | Collapsed-by-default transcript (screen fallback). |
| `Features/Map/MapView.swift` | MapKit map, user location, site pins within 100 m, optional debug radius circles. |
| `Features/Map/SiteDetailSheet.swift` | Manual play of a site’s stories (browse path, not the core loop). |
| `Features/History/HistoryView.swift` | Past walks; tap a row to replay audio. |
| `Features/Settings/SettingsView.swift` | Walking mode, languages, speed, permissions, debug links. |
| `Features/Debug/ProximityDebugView.swift` | Live fix, armed/disarmed distances, start/stop listening, last geofence wake. |
| `Features/Debug/ContentDebugView.swift` | Seeded sites/stories list with a play button. |

### 4.8 Shared UI, resources, tests

| Path | What it is |
|---|---|
| `Shared/SpeedChips.swift` | Speed picker chips. |
| `Shared/TriggerEventRow.swift` | One history row. |
| `Resources/denpasar.json` | MVP content pack (`AppConfig.contentPackName`). |
| `Resources/renon.json` | Alternate pack (not the default). |
| `Localizable.xcstrings` | String Catalog for SwiftUI literals. |
| `Info.plist` | `UIBackgroundModes`: `audio` and `location`. Location usage strings are in the Xcode target (`INFOPLIST_KEY_NSLocation…`). |
| `CooltourTests/` | Swift Testing coverage for prompts, coordinator, queue, history outcomes, language resolution, settings. |
| `Testing/DenpasarWalk.gpx` | Xcode location simulation through seeded sites. |

---

## 5. User flows

### 5.1 Cold launch

```
User taps the icon
        │
        ▼
CooltourApp.init
  • open SwiftData (Site, Story, Walk, TriggerEvent)
  • LocalContentStore.seedIfNeeded()   ← denpasar.json → database
  • build production services
  • AppEnvironment wires callbacks
  • if walkingMode already true in UserDefaults:
        proximity.start()
        history.startWalk()
        │
        ▼
RootView appears (Now / Map / History / Settings)
  • onAppear: start() again if walking mode is on (no-op if already listening)
```

Walking mode is **off by default**. A first-time user sees Now saying walking is off. Nothing listens until they opt in.

### 5.2 Turning walking mode on (the real “start listening”)

The toggle lives on **Now** and **Settings**. Both bind the same `SettingsStore.walkingMode`. `RootView` is the only place that reacts:

```
User turns Walking mode ON
        │
        ▼
SettingsStore persists AppConfig.walkingModeKey
        │
        ▼
RootView.onChange(of: walkingMode)
        ├── proximity.start()          ← engine starts GPS + geofences
        └── (Now also requests notification permission)
        │
        ▼
proximity.isListening becomes true
        │
        ▼
RootView.onChange(of: isListening)
        └── history.startWalk()        ← a Walk row opens
```

`start()` is idempotent (`guard !isListening else { return }`), so launch + `onAppear` + the toggle cannot stack two GPS loops.

### 5.3 Primary loop — walk up to a site

This is the product. Phone can be in a pocket.

```
Walking mode ON, CoreLocationProximityEngine listening
        │
        ▼
CLLocationUpdate.liveUpdates() delivers a fix
        │
        ▼
handle(_ location)
  • distance to every Site
  • ProximityEvaluator.evaluate(...)
        │
        ├── accuracy worse than 35 m  →  nothing (silence)
        ├── already inside, not yet past re-arm ring  →  nothing
        └── newly entered radius
                │
                ├── onEventLogged  →  HistoryStore.addEvent(.pending)
                └── onTrigger(site, story)
                        │
                        ▼
            ConsentNarrationCoordinator.handleTrigger
                        │
                        ├── already prompting  →  silently enqueue
                        └── else begin prompt:
                              • pause current story only for the spoken line
                              • SystemPromptVoice.speak("Approaching …")
                              • UNNotificationService.postPrompt
                              • (if idle) SystemConsentRemoteControl.arm  ← AirPod stem = Play
                              • Now shows Play / Queue / Dismiss
```

**Three answers, same coordinator methods:**

| Surface | Play now | Add to queue | Dismiss |
|---|---|---|---|
| Now buttons | `accept` | `queue` | `dismiss` |
| Notification actions | `accept` | `queue` | `dismiss` |
| AirPod stem (idle prompt only) | `accept` | — | — |
| Silence for 10 s after TTS | — | — | timeout → `timedOut` |

Then:

- **Play** → `AVAudioPlayerService.play(story:)` loads the bundled file for `settings.audioLanguage`. Missing Indonesian asset → silence, treated as dismiss.
- **Queue** → `WalkStoryQueue.enqueue`; when the current story finishes, `playbackDidFinish` pops the next one.
- **Dismiss / timeout** → resume the paused story if any, else idle.

GPS keeps running. Leaving the site past `triggerRadius × 1.35` **re-arms** it so a later visit can fire again. Standing on the boundary does not.

### 5.4 Turning walking mode off (the real “stop listening”)

```
User turns Walking mode OFF
        │
        ▼
RootView.onChange(of: walkingMode)
        ├── proximity.stop()           ← cancels GPS, invalidates background session,
        │                                 monitor task cancelled (next start clears geofences)
        └── storyQueue.clear()         ← later-list is walk-scoped
        │
        ▼
isListening = false
        └── history.stopWalk()
```

Location permission is **not** revoked in code. iOS still shows When In Use / Always until the user changes it in Settings. The app simply stops using location.

### 5.5 Background / lock screen / killed app

Two different Core Location jobs (do not conflate them):

| Mechanism | Job |
|---|---|
| `CLLocationUpdate.liveUpdates()` + `CLBackgroundActivitySession` | Keep precise fixes flowing while the app is backgrounded. |
| `CLMonitor` circular conditions (~150 m, `AppConfig.monitorWakeRadiusMeters`) | Wake or **relaunch** a terminated app when you walk near a site. |

A geofence wake does **not** play a story. It only records `lastWake`. The precise live fix still has to pass `ProximityEvaluator`.

`Info.plist` declares background modes `location` and `audio` so GPS and playback can continue with the screen off.

Authorization ladder inside `start()` / `refreshAuthorization()`:

1. `CLLocationManager.requestWhenInUseAuthorization()` if never asked.
2. After When In Use is granted **and** walking mode is on, `requestAlwaysAuthorization()` once. Always is required for lock-screen / terminated-app wakes.

### 5.6 Secondary flows

**Map (browse).** Pins for sites within 100 m of the last fix. Tap → `SiteDetailSheet` → manual `audio.play`. This bypasses the consent gate (deliberate play).

**History.** `@Query` of `Walk`s. Tap a `TriggerEvent` to replay that story.

**Simulate.** Now’s “Simulate pura approach” calls `proximity.simulateTrigger`, which fires the same `onEventLogged` → `onTrigger` path without GPS.

---

## 6. `CoreLocationProximityEngine` — start, stop, frameworks

This type is the production `ProximityEngine`. It is created in `CooltourApp` as:

```swift
proximity: CoreLocationProximityEngine(content: store)
```

Previews and tests inject `MockProximityEngine` instead, so they never touch GPS.

### 6.1 Frameworks

| Import | Why |
|---|---|
| **CoreLocation** | All of the actual sensing. `CLLocationManager` (permission prompts + status only — **not** the old delegate-based update loop). `CLLocationUpdate.liveUpdates()` for the fix stream. `CLMonitor` + `CLMonitor.CircularGeographicCondition` for geofence wakes. `CLBackgroundActivitySession` so live updates continue in the background. `CLLocation` for `distance(from:)`. |
| **UIKit** | `UIApplication.shared.applicationState` so a trigger can be tagged `wasBackground`. |
| **Foundation** | `Task`, `UserDefaults`, `Date`. |

It does **not** import MapKit, AVFoundation, or UserNotifications. Those belong to Map, audio, and notifications.

### 6.2 What starts listening

**Function: `start()`**

```56:96:Cooltour/Services/Location/CoreLocationProximityEngine.swift
  func start() {
    guard !isListening else { return }
    isListening = true
    // … request When In Use if needed …
    if backgroundEnabled {
      backgroundSession = CLBackgroundActivitySession()
    }
    monitorTask = Task { await self?.syncMonitor(enabled: backgroundEnabled) }
    updates = Task {
      for try await update in CLLocationUpdate.liveUpdates() {
        // handle(location) → evaluator → onTrigger
      }
      self?.stop()  // stream ended (auth revoked, session gone)
    }
  }
```

Callers of `start()`:

| Caller | When |
|---|---|
| `CooltourApp.init` | Walking mode was already on at process launch (including a Core Location relaunch with no UI). |
| `RootView.onAppear` | Walking mode on when the tab bar appears. |
| `RootView.onChange(of: walkingMode)` | User turns the toggle on. |
| `ProximityDebugView` | Manual “Start listening” (debug only). |

Inside `start()`, the work is:

1. Set `isListening = true`.
2. Ask for **When In Use** if status is `.notDetermined`.
3. If walking mode is on, create `CLBackgroundActivitySession`.
4. Start `syncMonitor` — register (or tear down) `CLMonitor` geofences for every site.
5. Start the `liveUpdates()` loop. Each `CLLocation` goes to `handle(_:)`.

The first good fix after When In Use is granted also calls `requestAlwaysAuthorization()` (once) so background wakes can work.

### 6.3 What stops listening

**Function: `stop()`**

```98:108:Cooltour/Services/Location/CoreLocationProximityEngine.swift
  func stop() {
    updates?.cancel()
    updates = nil
    monitorTask?.cancel()
    monitorTask = nil
    backgroundSession?.invalidate()
    backgroundSession = nil
    isListening = false
    cachedLocations.removeAll()
  }
```

That:

- Cancels the live GPS task (no more `handle(_:)`).
- Cancels the monitor task.
- **Invalidates** `CLBackgroundActivitySession` immediately (otherwise the background grant can linger until next launch).
- Clears the cached `CLLocation` per site.

Callers of `stop()`:

| Caller | When |
|---|---|
| `RootView.onChange(of: walkingMode)` | User turns walking mode **off**. This is the product stop. |
| `start()`’s `liveUpdates` loop | The stream **ended** (permission revoked mid-walk, or the background session went away). Stopping here keeps `isListening` from claiming a feed that already died. |
| `ProximityDebugView` | Manual stop, or leaving the debug screen while walking mode is off. |

**Not** stopped by: switching tabs, locking the screen, or backgrounding — those are why the background session and `CLMonitor` exist.

Note: cancelling `monitorTask` does not itself delete geofences. The next `start()` with walking mode off, or `syncMonitor(enabled: false)`, removes every identifier. Turning walking mode off currently cancels the task; geofence cleanup runs the next time `start()` syncs with `enabled: false`. The background session **is** ended immediately.

### 6.4 How a fix becomes a story (inside the engine)

```
liveUpdates() CLLocation
        │
        ▼
handle(_:)
  distance from user → each Site
        │
        ▼
ProximityEvaluator.evaluate
  reject if horizontalAccuracy <= 0 or > 35 m
  fire slug if newly inside triggerRadiusMeters
  re-arm slug if farther than radius × 1.35
        │
        ▼
publish lastFix + nearbySites (Now status, Map, debug)
        │
        ▼
for each newly fired slug (nearest first):
  onEventLogged(ProximityEvent)     → history (pending)
  onTrigger(site, story)            → only the nearest site
                                      (overlapping temples: one story, not two)
```

`onTrigger` is assigned in `AppEnvironment`, not in the engine. The engine does not know about audio or consent.

### 6.5 Protocol surface (what views see)

Views talk to `any ProximityEngine`, not the Core Location class:

- `isListening` — Now status line (“Listening…” vs “Starting…”).
- `authorizationStatus` — permission copy on Now and Settings.
- `lastFix` / `nearbySites` — Map, Now card distance, debug.
- `start()` / `stop()` — walking-mode toggle via `RootView`.
- `simulateTrigger(site:)` — Now debug button.

---

## 7. How the other engines start and stop

Same “who starts / who stops” question for the rest of the core loop.

| Concern | Starts | Stops |
|---|---|---|
| **Content seed** | `CooltourApp` → `seedIfNeeded()` once per launch | n/a (pack stays in SwiftData) |
| **Audio session** | `AVAudioPlayerService.play` activates `AVAudioSession` only when a file is ready | `stop()` / natural finish / AirPods removed → `setActive(false)` |
| **TTS prompt** | `promptVoice.speak` in `beginPrompt` | `promptVoice.stop` in `endPrompt` (user answered or timed out) |
| **Notification** | `postPrompt` when a prompt begins | `withdrawPrompt` when it resolves |
| **AirPod stem as consent** | `remoteControl.arm` when prompting **and** no story is loaded | `disarm` in `endPrompt` |
| **Walk record** | `history.startWalk` when `isListening` becomes true | `history.stopWalk` when listening stops |
| **Story queue** | `enqueue` from Queue button or a busy trigger | `clear()` when walking mode turns off; `popNext` after a story finishes |

---

## 8. Frameworks used (whole app)

| Framework | Where | For |
|---|---|---|
| **SwiftUI** | App, Root, every Feature, Shared | UI, tabs, Observation environment |
| **Observation** | Services that views read | `@Observable` state |
| **SwiftData** | Models, ContentStore, HistoryStore, HistoryView `@Query` | Persistence |
| **Core Location** | `CoreLocationProximityEngine`, Now/Settings (status display) | GPS, permissions, `CLMonitor`, background activity |
| **MapKit** | `MapView` | Map, user annotation, site pins |
| **AVFoundation** | `AVAudioPlayerService`, `SystemPromptVoice` | `AVAudioPlayer` + session; `AVSpeechSynthesizer` |
| **MediaPlayer** | `AVAudioPlayerService`, `SystemConsentRemoteControl` | Now Playing, remote commands, AirPod stem |
| **UserNotifications** | `UNNotificationService` | Local approach banners + actions |
| **UIKit** | Proximity engine, Settings “Open System Settings” | `UIApplication` state / settings URL |
| **Foundation** | Everywhere | Tasks, UserDefaults, dates |

**Not used in the running app (yet):** PHASE (`AppConfig.usePHASE = false`), Core Motion heading, WeatherKit, WatchConnectivity, any network SDK.

---

## 9. Data flow (one picture)

```
denpasar.json
      │ ContentStore.seedIfNeeded
      ▼
SwiftData  Site ──< Story
      │
      │ allSites()
      ▼
CoreLocationProximityEngine.start()
      │ liveUpdates + CLMonitor
      ▼
ProximityEvaluator  ──silence if inaccurate──► (nothing)
      │ fire
      ├── HistoryStore  TriggerEvent (.pending → outcome)
      └── ConsentNarrationCoordinator.handleTrigger
                ├── PromptVoice (TTS)
                ├── NotificationService (banner)
                ├── ConsentRemoteControl (stem)
                └── on accept: AudioPlayerService.play(Story)
                                      │
                                      ▼
                               bundled .m4a / audio file
```

---

## 10. Related docs

| Doc | Use |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | How to change this repo (architecture rules, git, testing). |
| [`InitialCooltour.md`](InitialCooltour.md) | Slice plan and original product spec. Some early slices still mention auto-play; the running app is consent-first. |
| [`AudioArchitectureAnalysis.md`](AudioArchitectureAnalysis.md) | Why audio is bundled, not streamed. |
| [`FEATURE_now_screen_audio_player.md`](FEATURE_now_screen_audio_player.md) | Now-card player notes. |
| [`MilaSlices.md`](MilaSlices.md) | Slice ownership notes. |
| [`PRD-AppleWatchCompanion.md`](PRD-AppleWatchCompanion.md) | Watch product requirements. |
| [`WatchSlices.md`](WatchSlices.md) | Watch build plan (Slices 17–21). Not built yet. |
