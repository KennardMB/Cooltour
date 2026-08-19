# Feature Spec: Audio Player on Now Screen (Home Tab)
**Project:** Cooltour (codename: Nyasar)  
**Slice reference:** Slice 5 — "The Now Screen"  
**Status:** Ready to build  
**Author:** Tami  
**Date:** 2026-08-18

---

## Problem

`AudioPlayerService` (built in Slice 2) is fully functional — play, pause, resume, speed control, and background audio all work. However, the only UI to access it is a **temporary debug screen** buried in Settings. There is no audio player on the home screen (Now tab) where it belongs.

**Current state:**
- Audio controls live in a debug/temp UI in Settings
- Now tab shows only placeholder content
- Users cannot play a story from the home screen

**Desired state:**
- Now tab is the primary surface for audio playback
- Settings debug UI is removed or hidden behind a debug flag
- Single source of truth: controls on Now screen and Settings stay in sync

---

## Goal

Move the audio player experience to its rightful home — the **Now tab** — by building the real Now screen UI and wiring it to the existing `AudioPlayerService`.

> No new audio logic is needed. This is purely a UI + wiring task.

---

## Scope

### In scope
- Build `NowView` as the real home tab content
- Wire `NowView` to the existing `AudioPlayerService`
- Status line (proximity/listening state)
- Now card (currently playing story)
- Transcript disclosure (collapsed by default)
- Quick controls: play/pause, speed selector chips
- Today's walk feed (in-session trigger list)
- Teaser: show nearest site when nothing is playing yet
- Remove or flag-gate the temporary debug audio UI from Settings

### Out of scope
- Proximity triggering (Slice 3) — use manual play for now
- Persisting the feed across launches (Slice 8)
- Map tab changes
- New audio logic

---

## UI Structure

```
NowView
├── Status line
│     "Listening for nearby stories" / "3 stories nearby" / "Nothing nearby"
│
├── Now card  (shown when a story is active or was last played)
│     ├── Site name + distance
│     ├── Story title + short snippet
│     ├── Play/Pause button  ← large, thumb-friendly
│     ├── Speed chips: 0.75× | 1× | 1.25× | 1.5×
│     └── "Transcript ▾" disclosure → full transcript (collapsed by default)
│
├── Quick controls  (always visible)
│     ├── Auto-play toggle
│     └── Speed selector chips (mirrors Now card; both write to SettingsStore)
│
└── Today's walk feed
      ├── Each triggered story → tappable to replay
      └── Empty state: "Coming up: [nearest site] — 80m"
```

---

## Files to Create / Modify

### New files
| File | Folder |
|---|---|
| `NowView.swift` | `Cooltour/Features/Now/` |
| `NowViewModel.swift` | `Cooltour/Features/Now/` |
| `NowCard.swift` | `Cooltour/Features/Now/` |
| `TranscriptDisclosure.swift` | `Cooltour/Features/Now/` |
| `SpeedChips.swift` | `Cooltour/Shared/` |

### Files to modify
| File | Change |
|---|---|
| `ContentView.swift` or root tab view | Replace Now tab placeholder with `NowView` |
| `SettingsView.swift` | Remove or flag-gate temporary debug audio UI |
| `SettingsStore.swift` | Expose `playbackSpeed` and `autoPlay` as `@AppStorage` properties (if not already) |

---

## Data Flow

```
SettingsStore (@AppStorage)
      ↑ ↓  (read/write)
NowViewModel
      ↑ ↓  (observed)
AudioPlayerService (@Observable)
      ↑
NowView / NowCard / SpeedChips
```

- `NowViewModel` observes `AudioPlayerService` for playback state
- Speed and auto-play changes write to `SettingsStore` — single source of truth
- `NowView` reads from `NowViewModel` only — no direct service access from views

---

## Acceptance Criteria

- [ ] Now tab shows the audio player UI (not a placeholder)
- [ ] Tapping play/pause on Now card controls audio correctly
- [ ] Speed chips on Now card update playback speed immediately
- [ ] Speed chips and auto-play toggle match what's set in Settings (in sync)
- [ ] Transcript expands/collapses on tap, collapsed by default
- [ ] Today's walk feed shows stories played this session
- [ ] When nothing is playing, teaser shows nearest site name + distance
- [ ] Temporary debug audio UI is gone from Settings (or behind a debug flag)
- [ ] Preferences persist after relaunch (from SettingsStore)
- [ ] App compiles and runs without errors

---

## Prompt for Claude Code

Paste this into Claude Code to start building:

```
Kita sedang mengerjakan Slice 5 dari InitialCooltour.md.

AudioPlayerService dari Slice 2 sudah lengkap dan berjalan dengan baik.
Masalahnya: UI audio player saat ini hanya ada di debug UI sementara di Settings.
Kita perlu memindahkannya ke Now tab (home screen).

Tolong:
1. Baca CLAUDE.md, AGENTS.md, dan documents/InitialCooltour.md terlebih dahulu
2. Cari di mana debug audio UI saat ini berada di Settings
3. Buat NowView, NowViewModel, dan komponen pendukungnya sesuai spec di FEATURE_now_screen_audio_player.md
4. Wire NowView ke AudioPlayerService yang sudah ada
5. Hubungkan ke SettingsStore sebagai single source of truth
6. Hapus atau flag-gate debug audio UI dari Settings

Jangan buat logic audio baru — cukup hubungkan yang sudah ada ke UI yang proper.
Sebutkan folder path lengkap untuk setiap file baru yang dibuat.
```

---

## Notes

- Audio logic **tidak perlu diubah** — Slice 2 sudah solid
- Proximity triggering belum ada (Slice 3), jadi untuk testing gunakan tombol manual play
- Prioritaskan tombol play/pause yang besar — konteks walking, layar disentuh sambil jalan
- Transcript selalu collapsed by default — audio adalah primary, teks adalah fallback
