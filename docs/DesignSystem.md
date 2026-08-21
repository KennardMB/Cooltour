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
- **Visuals**: 60pt / 40pt height, 4pt border (`#821111`), 4pt corner radius.
- **States**:
  - *Active*: bg `#D81D1D`, border `#821111`, text `#FEFEFE` (`Baru Lagi` 20pt / 16pt).
  - *Pressed*: bg `#821111`, border `#821111`, text `#FEFEFE`.

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
- **Features**: Interactive size, unlocked/locked states with grayscale and lock indicator.

```swift
AchievementBadge(.travelerSpecial, isUnlocked: true)
```

### 7. `AppIcon` (Custom Brush Audio & Navigation Icons)
- **Assets**: `IconForward10`, `IconRewind10`, `IconPlaybackSpeed`, `IconQueue`, `IconArrowDown`, `IconArrowUp`, `IconDirectionLeft`, `IconDirectionRight`, `IconClose`, `IconSlideHandle`, `IconSpeed0_5`...`IconSpeed1_5`.
- **Usage**: Type-safe vector icon component with optional explicit size.

```swift
AppIcon(.forward10, size: 36)
AppIcon(.playbackSpeed, size: 32)
```

### 8. `PlaybackSpeedSheet` (Speed Selector Modal)
- **Options**: `0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`.
- **Features**: Interactive selection with custom speed brush icons, selected highlight, and dismiss action.

```swift
PlaybackSpeedSheet(selectedSpeed: $speed, onClose: { showSheet = false })
```

### 9. `AudioScrubber` (Playback Timeline)
- **Features**: Interactive progress drag scrubber with elapsed and remaining timestamps, custom thumb, and VoiceOver percentage announcements.

```swift
AudioScrubber(progress: $progress, durationSeconds: story.durationSeconds) { seekSeconds in
    audio.seek(to: seekSeconds)
}
```

### 10. `ColorThemeSelector` (Cultural Palette Switcher)
- **Colors**: Royal Azure, Pink Carnation, Bright Gold, Tiger Flame, Jade Green.

```swift
ColorThemeSelector(selectedTheme: $theme)
```

### 11. `ListButton` (Story & Queue Rows)
- **Visuals**: Reusable card row with title, relative direction/distance, duration text, and right-aligned Play icon button.

```swift
ListButton(title: "Pura Jagatnatha", subtitle: "80m · on your left", durationText: "1:45", onPlay: { ... })
```

### 12. `DirectionBadge` (Relative Wayfinding Indicator)
- **Visuals**: Direction arrows (`IconDirectionLeft`, `IconDirectionRight`) with distance phrase.

```swift
DirectionBadge("80m · on your left", direction: .left)
```

---

## 6. Accessibility & Concurrency Guidelines

1. **VoiceOver Support**: Every button and card must declare `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityAddTraits`.
2. **Dynamic Type Scaling**: Use `@ScaledMetric` on custom layout dimensions so touch targets expand proportionally.
3. **Strict Concurrency (`@MainActor`)**: All views and modifiers run on `@MainActor` with zero data races per `AGENTS.md`.



