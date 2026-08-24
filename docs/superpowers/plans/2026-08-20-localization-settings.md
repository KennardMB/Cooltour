# Localization Settings Implementation Plan

> **For agentic workers:** Execute task-by-task. Steps use checkbox syntax.

**Goal:** Add independent app-language and story-audio settings, localize UI chrome, and silence when Indonesian audio is missing.

**Architecture:** Preferences live in `SettingsStore`. App locale is applied at the root. Audio resolution uses story bilingual fields; failed resolve returns `false` from `play`.

**Tech Stack:** SwiftUI, String Catalog, UserDefaults, AVFoundation

## Global Constraints

- iOS 26.5+, Swift 6, Observation / `@Observable` SettingsStore
- No English audio fallback when ID is selected and missing
- Brand name only via `AppConfig.appName`
- Do not commit unless the human asks

---

### Task 1: Preference types + SettingsStore

**Files:**
- Create: `Cooltour/Services/Settings/AppLanguagePreference.swift`
- Create: `Cooltour/Services/Settings/AudioLanguagePreference.swift`
- Modify: `Cooltour/Services/Settings/SettingsStore.swift`
- Test: `CooltourTests/SettingsStoreLocalizationTests.swift`

- [ ] Add enums + persist `appLanguage` / `audioLanguage`
- [ ] Add `effectiveLocale` computed property
- [ ] Test round-trip persistence

### Task 2: Story resolution helpers

**Files:**
- Modify: `Cooltour/Models/Story.swift`

- [ ] `audioAssetName(for:)`, `transcript(for:)`, `durationSeconds(for:)` with ID → nil asset when missing

### Task 3: Audio play returns Bool + settings-aware resolve

**Files:**
- Modify: `AudioPlayerService.swift`, `AVAudioPlayerService.swift`, `MockAudioPlayerService.swift`
- Modify: `CooltourApp.swift`, `ConsentNarrationCoordinator.swift`
- Modify: Map/History/Debug play call sites if needed

- [ ] Inject `SettingsStore` into `AVAudioPlayerService`
- [ ] `play(story:) -> Bool`; false on missing asset
- [ ] Coordinator accept / queue advance dismisses on false

### Task 4: Settings UI + root locale

**Files:**
- Modify: `SettingsView.swift`, `RootView.swift` or `CooltourApp.swift`
- Create: `Cooltour/Localizable.xcstrings`
- Modify: `project.pbxproj` knownRegions (`id`)
- Localize primary chrome strings (tabs, Settings, Now)

- [ ] Language section with both pickers + ID audio footer
- [ ] Apply `.environment(\.locale, settings.effectiveLocale)`
