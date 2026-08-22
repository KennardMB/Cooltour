# Cooltour Design System

> **Single Source of Truth** for all design tokens, custom typography, color palettes, atomic components, and accessibility standards for the Cooltour iOS application.

---

## 1. Design Principles & Aesthetic

1. **Tactile Brutalism & Clarity**: High-contrast, bold 4pt solid borders, 4pt corner radii, and solid color swatches that remain legible in direct sunlight when walking outdoors.
2. **Audio-First & Screen-Free Attention**: Large, thumb-sized touch targets (minimum 44pt, standard 60pt button height) allowing quick interaction without looking down at the phone.
3. **Harmonious Cultural Palette**: Grounded in Bali-inspired vibrant accents (Royal Azure, Pink Carnation, Bright Gold, Tiger Flame, Jade Green) balanced by warm neutral canvas backgrounds (`#F8F7F4`).
4. **Offline & System Integrated**: Custom font assets bundled locally and mapped to standard Dynamic Type text styles with full VoiceOver support.

---

## 2. Typography System

The app utilizes a dual-typography hierarchy:
- **Display & Cultural Headings**: Custom Display font **`Sore-Bold`** (Internal PostScript Name: `BaruLagi-Regular`, Full Name: `Baru Lagi Regular`).
- **Body, Captions & System UI**: **`SF Pro`** for clean, legible, and standard iOS typography.

### Font Registration
- **File**: `Cooltour/Resources/Fonts/Sore-Bold.ttf`
- **Info.plist**: `UIAppFonts` → `Sore-Bold.ttf`
- **PostScript Name**: `BaruLagi-Regular`

### Typography Hierarchy Table

| Token | Font Family | Size | Weight | Line Height | Tracking | Usage |
|---|---|---|---|---|---|---|
| `appFont(.heading1)` | `BaruLagi-Regular` | 32pt | Bold (Regular) | 1.6 (~51pt) | 0 | Screen display titles, site names |
| `appFont(.heading2)` | `BaruLagi-Regular` | 28pt | Bold (Regular) | 1.4 (~39pt) | 0 | Section headers, sheet titles |
| `appFont(.heading3)` | `BaruLagi-Regular` | 20pt | Bold (Regular) | 1.2 (~24pt) | 0 | Card titles, primary button text |
| `appFont(.title)` | `BaruLagi-Regular` | 16pt | Bold (Regular) | 1.2 (~19pt) | 0 | Small headings, badge labels |
| `appFont(.titleL)` | `SF Pro` | 24pt | Bold | 1.2 (~29pt) | 0 | Large system headers |
| `appFont(.titleM)` | `SF Pro` | 20pt | Semibold | 1.2 (~24pt) | 0 | Sub-headers, modal titles |
| `appFont(.captionL)` | `SF Pro` | 16pt | Regular | 1.2 (~19pt) | 0 | Primary body text, transcripts |
| `appFont(.captionS)` | `SF Pro` | 14pt | Regular | 1.2 (~17pt) | 0 | Secondary descriptions, timestamps |
| `appFont(.label)` | `SF Pro` | 12pt | Regular | 1.2 (~14pt) | 0 | Metadata, distances, pill badges |


---

## 3. Color System

All colors are defined as semantic tokens under `AppColor` with explicit hex constants and high WCAG AAA contrast ratings.

### Canvas & Backgrounds

| Token | Hex Value | RGB | Semantic Role |
|---|---|---|---|
| `AppColor.Background.pure` (`Background-50`) | `#FEFEFE` | `(254, 254, 254)` | Card backgrounds, elevated surfaces |
| `AppColor.Background.canvas` (`Background-100`) | `#F8F7F4` | `(248, 247, 244)` | Main screen background (warm off-white) |
| `AppColor.Background.border` (`Background-800`) | `#E2E1DE` | `(226, 225, 222)` | Standard 4pt card border, dividers |
| `AppColor.Background.muted` (`Background-900`) | `#686866` | `(104, 104, 102)` | Dark neutral borders / disabled icons |

### Text & Grays

| Token | Hex Value | RGB | Semantic Role |
|---|---|---|---|
| `AppColor.Text.primary` (`Black-3`) | `#111111` | `(17, 17, 17)` | Primary headlines, story titles |
| `AppColor.Text.secondary` (`Black-2`) | `#393939` | `(57, 57, 57)` | Body copy, transcript text, captions |
| `AppColor.Text.subtle` (`Black-1`) | `#E7E7E7` | `(231, 231, 231)` | Light dividers, placeholder tints |

### Primary Brand (Royal Azure)

| Token | Hex Value | RGB | Semantic Role |
|---|---|---|---|
| `AppColor.Brand.tint` (`Blue-50`) | `#E8EEFB` | `(232, 238, 251)` | Profile avatar BG, disabled button BG |
| `AppColor.Brand.primary` (`Blue-100`) | `#1D52D8` | `(29, 82, 216)` | Primary CTA background, active state |
| `AppColor.Brand.dark` (`Blue-200`) | `#113182` | `(17, 49, 130)` | Primary button 4pt border, pressed BG |

### Secondary & Destructive (Red)

| Token | Hex Value | RGB | Semantic Role |
|---|---|---|---|
| `AppColor.Destructive.tint` (`Red-Disabled`) | `#FBE8E8` | `(251, 232, 232)` | Disabled destructive BG |
| `AppColor.Destructive.primary` (`Red-Active`) | `#D81D1D` | `(216, 29, 29)` | Dismiss / skip buttons, danger actions |
| `AppColor.Destructive.dark` (`Red-Pressed`) | `#821111` | `(130, 17, 17)` | Destructive 4pt border, pressed BG |

### Accent Palette

| Accent Group | 50 (Tint) | 100 (Core Active) | 200 (Dark / Border) | Identity |
|---|---|---|---|---|
| **Accent 1 (Blue)** | `#E8EEFB` | `#1D52D8` | `#113182` | Royal Azure |
| **Accent 2 (Pink)** | `#FFE2EF` | `#FD87BB` | `#904D6B` | Pink Carnation |
| **Accent 3 (Yellow)** | `#FFF6C7` | `#FFD817` | `#917B0D` | Bright Gold |
| **Accent 4 (Orange)** | `#FFDACE` | `#FF6634` | `#913A1E` | Tiger Flame |
| **Accent 5 (Green)** | `#C2EDD5` | `#01B552` | `#01672F` | Jade Green |

---

## 4. Spacing & Dimensions

Based on a **4pt / 8pt grid scale**:

- **Corner Radius**: `AppRadius.standard = 4pt` (Brutalist tactile aesthetic), `AppRadius.pill = 999pt` (Badges).
- **Border Width**: `AppBorderWidth.standard = 4pt` (Heavy distinct borders), `AppBorderWidth.thin = 1pt`.
- **Button Heights**:
  - `AppDimension.buttonHeightLarge = 60pt`
  - `AppDimension.buttonHeightSmall = 40pt`
  - `AppDimension.iconButtonSize = 60pt`
  - `AppDimension.avatarSize = 40pt`
- **Spacing Scale**:
  - `AppSpacing.xxs = 2pt`
  - `AppSpacing.xs = 4pt`
  - `AppSpacing.sm = 8pt`
  - `AppSpacing.md = 12pt`
  - `AppSpacing.lg = 16pt`
  - `AppSpacing.xl = 24pt`
  - `AppSpacing.xxl = 32pt`

---

## 5. Atomic Components & Swift Usage

### 1. `AppButton` (Primary CTA)
- **Visuals**: 60pt height, 4pt border (`#113182`), 4pt corner radius.
- **States**:
  - *Active*: bg `#1D52D8`, border `#113182`, text `#FEFEFE` (`Baru Lagi` 20pt).
  - *Pressed*: bg `#113182`, border `#113182`, text `#E2E1DE`.
  - *Disabled*: bg `#E8EEFB`, border `#FEFEFE`, text `#8E98A8`.
- **Pre-rendered Brush Variants**:
  - `AppButton(variant: .startExploration)` — Uses `BrushButtonPlayActive` / `BrushButtonDefaultDisabled` / `BrushButtonDefaultPressed`.
  - `AppButton(variant: .pauseExploration)` — Uses `BrushButtonPauseActive`.

```swift
AppButton(variant: .startExploration) {
    // Start exploration action
}
```

### 2. `AppIconButton` (60×60pt Square Controls)
- **Visuals**: 60×60pt square button with 4pt brush stroke border.
- **Variants**:
  - `.play` — Renders `BrushIconButtonPlay`
  - `.pause` — Renders `BrushIconButtonPause`

```swift
AppIconButton(.play) {
    // Play story
}
```

### 3. `AppDestructiveButton` (Dismiss / Skip)
- **Visuals**: 60pt (Large) / 40pt (Small) height, authentic brush stroke backgrounds (`BrushButtonDestructiveActiveLarge`/`Small`, `BrushButtonDestructivePressedLarge`/`Small`, `BrushButtonDestructiveDisabledLarge`/`Small`).
- **States**:
  - *Active*: Red brush stroke with `#FEFEFE` text (`Baru Lagi` 20pt / 16pt).
  - *Pressed*: Dark red pressed brush asset.
  - *Disabled*: Muted disabled brush asset.

```swift
AppDestructiveButton("Dismiss", size: .large) {
    // Action
}
```

### 4. `AppProfileButton` (Avatar Badge)
- **Visuals**: 40x40pt, hand-drawn brush outline (`BrushProfile`), initial text in `Baru Lagi` 20pt `#1D52D8`.

```swift
AppProfileButton(initial: "A") {
    // Profile action
}
```

### 5. `AppCard` (Container)
- **Visuals**: Supports `.standard` (4pt `#E2E1DE` border) and `.brush` (hand-drawn `BrushCard` outline).
- **Header**: `Baru Lagi` 16pt `#111111`.
- **Subheadline**: `SF Pro` 12pt `#393939`.

```swift
AppCard(title: "Pura Maospahit", caption: "80m · on your left", style: .brush) {
    // Card content
}
```

### 6. `AchievementBadge` (Cultural Badges)
- **Assets**: `BadgeTravelerSpecial`, `BadgeSunnySideUp`, `BadgeExplorer`.
- **Features**: Scalable size, title and VoiceOver hints.

```swift
AchievementBadge(.travelerSpecial)
```

### 7. `AppIcon` (Custom Brush Audio & Navigation Icons)
- **Assets**: `IconForward10`, `IconRewind10`, `IconPlaybackSpeed`, `IconQueue`, `IconChevronDown`, `IconChevronUp`, `IconChevronLeft`, `IconChevronRight`, `IconClose`, `IconCheck`, `IconSlideHandle`, `IconSpeed0_5`...`IconSpeed1_5`.
- **Usage**: Type-safe vector icon component with optional explicit size and `.forSpeed(rate)` mapping.

```swift
AppIcon(.forward10, size: 36)
AppIcon(.playbackSpeed, size: 32)
```

### 8. `PlaybackSpeedPicker` (Horizontal Speed Slider)
- **Visuals**: Pre-rendered brush slider steps (`BrushSpeedOption0_5`...`BrushSpeedOption1_5`) per Figma Node `194:28`.
- **Options**: `0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`.
- **Features**: Interactive horizontal tap & drag zones, VoiceOver adjustable actions, and sheet container (`PlaybackSpeedSheet`).

```swift
PlaybackSpeedPicker(selectedSpeed: $speed)
```

### 9. `AudioScrubber` (Figma Node 194:211)
- **Visuals**: 3-part atomic brush construction:
  1. `BrushScrubberTrackWhite` (white background track frame)
  2. `BrushScrubberTrackBlue` (blue progress fill track, masked by progress)
  3. `BrushScrubberThumb` (13×32pt thumb indicator)
- **Features**: Full interactive drag seeking with elapsed and remaining timestamps.

```swift
AudioScrubber(progress: $progress, durationSeconds: story.durationSeconds) { seekSeconds in
    audio.seek(to: seekSeconds)
}
```

### 10. `ColorThemeSelector` (Cultural Palette Switcher)
- **Visuals**: Authentic `BrushColorChooseOptions` (359×35) palette with smooth animated `IconCheck` overlay on selected theme.
- **Colors**: Royal Azure, Pink Carnation, Jade Green, Bright Gold, Tiger Flame.

```swift
ColorThemeSelector(selectedTheme: $theme)
```

### 11. `ListButton` (Story & Queue Rows)
- **Visuals**: Reusable card row with title, relative direction/distance, duration text, and right-aligned Play icon button.

```swift
ListButton(title: "Pura Jagatnatha", subtitle: "80m · on your left", durationText: "1:45", onPlay: { ... })
```

### 12. `TiledBackgroundView` (Tiled Grid Background)
- **Visuals**: High-performance GPU-tiled grid (`BrushBackgroundTile` 124×124).
- **Scale Customization (1:1 with Figma Tile %)**:
  - `scale`: Relative tile width percentage compared to screen width (e.g. `0.20` = 20%, `0.60` = 60%).
  - `tilesPerRow`: Explicit count of tiles per row (e.g. `tilesPerRow: 5` or `tilesPerRow: 2`).
- **Styles**:
  - `.default` / `defaultTiledBackground(scale:)`: Standard warm off-white canvas (`#F8F7F4`) with subtle 35% tile opacity (default `scale: 0.20` = 20%).
  - `.theme(CulturalColorTheme)` / `culturalTiledBackground(theme:scale:)`: Vibrant theme-tinted backgrounds for special celebratory views (default `scale: 0.60` = 60% matching Figma celebration art).

```swift
// Default screen background (20% tile scale)
ProfileView()
    .defaultTiledBackground(scale: 0.20)

// Special celebratory themed background (60% large tiles)
ExplorationDoneView()
    .culturalTiledBackground(theme: selectedTheme, scale: 0.60)
```

### 13. `PostageStatBadge` & `ExplorationSummaryStats` (Figma Node 196:233)
- **Visuals**: Scalloped postage ticket cards (`BrushPostageOrange`, `BrushPostagePink`) with custom icons (`IconPlaceVisited`, `IconDistance`) and `Baru Lagi` headline metrics.

```swift
ExplorationSummaryStats(placesVisitedCount: 11, distanceKm: 7.7)
```

### 14. `ExplorationBinderCard` (Figma Node 202:1287)
- **Visuals**: 3-hole notebook binder punch ticket card (`356×120pt`) with dynamic cultural theme palette (Pink, Orange, Blue, Green, Yellow).
- **Features**: Displays exploration title in `Baru Lagi` 16pt with start time and date stamps in `SF Pro` 12pt.

```swift
ExplorationBinderCard(
    title: "sabtu sama kean tami nanda nisa shin ke gajah mada",
    timeText: "11.30 AM",
    dateText: "21/12/2025",
    theme: .pink
)
```

### 15. `SitePolaroidCard` & `SitePolaroidCollage` (Figma Node 204:2091)
- **Visuals**: Tactile Polaroid photo frame with handwritten-style site caption in `Baru Lagi` display font.
- **Collage Layout**: Dynamic staggered 3D collage with playful rotation angles (`-8°`, `+7°`, `-1°`).
- **Asset Resolution**: Resolves image files dynamically from `Resources/SitePictures/<slug>.jpg` or `Assets.xcassets`.

```swift
SitePolaroidCollage(sites: [
    (name: "Pasar Kumbasari", imageAssetName: "pasar-kumbasari.jpg"),
    (name: "Pasar Badung", imageAssetName: "pasar-badung.jpg"),
    (name: "Nadhi Heritage", imageAssetName: "nadhi-heritage.jpg")
])
```

### 16. `SitesPlayerView` & `PauseTourOverlay` (Figma Nodes 209:3233, 209:3795)
- **Sites Player**: Regional location indicator ("You are now in <Subdistrict, Region, Province>"), red pause button, POI detection banner with "Open Map" link, photo carousel card, tactile `AudioScrubber`, and audio controls toolbar powered by `AppIcon`.
- **Pause Tour Overlay**: 96% opacity backdrop (`#E2E1DE`) displaying "done wandering? all the places will be saved once you ended it." with tactile blue "resume" and red "end tour" buttons.

### 17. `PlaybackSpeedSheet` & `StoryQueueSheet` (Figma Nodes 210:1033, 210:1078)
- **Playback Speed Half-Sheet (`210:1033`)**: 356pt white card with 4pt `#E7E7E7` border, `Baru Lagi` header, close button, and horizontal `PlaybackSpeedPicker` (0.5x, 0.75x, 1x, 1.25x, 1.5x) sliding over a 90% opacity `#E2E1DE` backdrop.
- **Queue Half-Sheet (`210:1078`)**: 356pt white card displaying "Now Playing" with active site title in `Baru Lagi` 20pt blue, remaining time, mini 40x40 play/pause button, and "Next stops:" section with dynamic queued sites from `env.storyQueue` and reorder handles (`IconSlideHandle`).

### 18. `FullTranscriptSheet` (Figma Node 210:1123)
- **Visuals**: Full vibrant Coral (`#FF6634`) canvas with top header (Site Title in `Baru Lagi` 24pt white with full multi-line display up to 50 characters, District in `SF Pro` 16pt, and dismiss `AppIcon(.chevronDown)` in white).
- **Karaoke Highlight Reader**: Interactive scrollable transcript where the current active sentence is highlighted inside a white card pill (`#FEFEFE`) with bold coral text, surrounded by inactive lines in `#FFDACE`.
- **SVG Audio Controls & Color Modifiers**:
  - `IconRewind10` and `IconForward10` SVGs use `currentColor` and template rendering mode, allowing dynamic tinting via `.foregroundStyle(...)`.
  - `AudioScrubber` supports `theme: .orange` (peach track `#FFDACE`, `#C44B25` stroke, and peach thumb `#FFDACE`).
  - Play/Pause button uses `BrushIconButtonPlayOrange` / `BrushIconButtonPauseOrange` (60x60) in Peach/Dark Coral palette.

```swift
SitesPlayerView()
    .environment(env)
```

---

## 6. Accessibility & Concurrency Guidelines

1. **VoiceOver Support**: Every button and card must declare `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityAddTraits`.
2. **Dynamic Type Scaling**: Use `@ScaledMetric` on custom layout dimensions so touch targets expand proportionally.
3. **Strict Concurrency (`@MainActor`)**: All views and modifiers run on `@MainActor` with zero data races per `AGENTS.md`.

---

## 7. Content Pack & Site Pictures Reference

- **Location**: `Cooltour/Resources/SitePictures/`
- **Schema (`denpasar.json`)**:
  ```json
  {
    "slug": "pura-maospahit",
    "name": "Pura Maospahit",
    "imageFile": "pura-maospahit.jpg",
    "stories": [...]
  }
  ```
- **Site Model**: `Site.thumbnailAssetName` maps to the site's `imageFile` string, loaded automatically by `ContentStore`.






