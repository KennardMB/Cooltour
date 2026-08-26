# EndView — Post-Tour Completion Screen

**Date:** 2026-08-27  
**Status:** design approved — implementing  
**Surface:** After End Tour from `PauseTourOverlay`

## Goal

After the user ends a tour, show a completion summary (`EndView`) before returning home, so they can name/theme the walk and confirm with **Save & Continue**.

## Locked decisions

| # | Decision |
|---|---|
| 1 | Save the walk **on End Tour** (same teardown as today). |
| 2 | Presentation: `fullScreenCover` from `NowView` (Approach A). |
| 3 | Skip `EndView` when the walk has **zero** trigger events (go straight home). |
| 4 | No back chevron; **Save & Continue** is the only exit. |
| 5 | No Edit modal / Edit button — **inline** title field + theme selector **below the collage**. |
| 6 | Headline above collage: **"Completed exploration!"** |
| 7 | Otherwise reuse the exploration-details body: collage, summary stats, timeline with replay. |
| 8 | Floating bottom CTA uses **BrushRowButton** asset, label **"Save & Continue"**. |

## Flow

```
Pause → End Tour → stop/save walk → (events?) EndView → Save & Continue → home
                              ↘ none → home
```

1. Capture `history.activeWalk` (and whether it has events) **before** teardown.
2. Teardown: dismiss pause overlay (+ sites player if open), `walkingMode = false`, `proximity.stop()`, `audio.stop()`. `RootView` already calls `history.stopWalk()` when listening stops.
3. If events ≥ 1 → present `EndView(walk:)`.
4. Save & Continue → persist title/theme if needed → dismiss cover → idle home.

## Layout (top → bottom)

1. Headline: `Completed exploration!`
2. `SitePolaroidCollage`
3. Editable title (`TextField`, 50-char cap) + `ColorThemeSelector` (live theme updates tiled background)
4. `ExplorationSummaryStats`
5. Timeline rows (same behavior as details)
6. Floating `BrushRowButton` — Save & Continue

## Files

| File | Role |
|---|---|
| `Features/Exploration/EndView.swift` | New completion screen |
| `Features/Exploration/TimelineStoryRow.swift` | Extract shared timeline row from details |
| `Features/Exploration/MyExplorationDetailsView.swift` | Use shared timeline row |
| `Features/Now/NowView.swift` | End Tour → capture walk → present cover |

## Non-goals

- Changing empty-walk discard behavior in `HistoryStore`
- Redesigning `MyExplorationDetailsView` beyond sharing the timeline row
- Watch / notification surfaces for this screen
