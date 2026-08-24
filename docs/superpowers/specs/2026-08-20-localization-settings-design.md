# Localization Settings Design

**Date:** 2026-08-20  
**Branch:** `feature/slice-localization-setting`  
**Status:** Approved

## Decisions

1. **App language:** `system` | `en` | `id` — default `system`, optional in-app override via `.environment(\.locale)`.
2. **Story audio language:** `en` | `id` — independent of app language; default `en`.
3. **Missing Indonesian audio:** no English fallback — silence / dismiss (failed play).
4. **UI strings:** String Catalog (`Localizable.xcstrings`) for chrome; JSON content titles stay as authored.

## Persistence (`SettingsStore`)

| Preference | Key | Default |
|---|---|---|
| App language | `cooltour_app_language` | `system` |
| Audio language | `cooltour_audio_language` | `en` |

## Playback

Resolve asset / duration / transcript from `audioLanguage`. If asset name is nil or not in the bundle → `play` returns `false`; callers dismiss / return to idle.

## Out of scope

Recording ID audio · full debug string localization · changing iOS system language.
