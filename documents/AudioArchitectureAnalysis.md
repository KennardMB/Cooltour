# Audio Delivery & Storage Architecture Analysis
**App:** Cooltour (*Codename: Nyasar*)  
**Audience:** Team Cooltour / Apple Developer Academy contributors  
**Related Docs:** [`documents/InitialCooltour.md`](InitialCooltour.md), [`AGENTS.md`](../AGENTS.md)  

---

## 1. Executive Summary & Core Recommendation

The core dilemma of Cooltour is balancing **device storage footprint** against **proximity trigger responsiveness** and **offline reliability**.

```
                           THE PROXIMITY DILEMMA
┌──────────────────────────────────────┐  vs  ┌──────────────────────────────────────┐
│        100% LOCAL BUNDLE             │      │        100% CLOUD STREAMING          │
│ • Zero trigger latency (instant)     │      │ • Zero initial storage footprint     │
│ • 100% offline & screen-free         │      │ • Instant OTA content updates        │
│ • App bundle bloats with 1000+ pins  │      │ • 2-5s buffering latency (walk-bys)  │
│                                      │      │ • Fails in cellular dead zones       │
└──────────────────────────────────────┘      └──────────────────────────────────────┘
                                      │
                                      ▼
             ┌──────────────────────────────────────────────────┐
             │       THE OPTIMAL HYBRID ARCHITECTURE            │
             │  "Local Execution, Predictive Cloud Delivery"    │
             │                                                  │
             │ 1. Voice-optimized compression (32-48 kbps AAC)  │
             │    → 100 stories is ONLY ~25 MB (not hundreds)   │
             │ 2. Regional Content Packs for multi-city scale   │
             │    (Phase 2 — deferred until after exhibition)   │
             │ 3. Predictive Geofenced Pre-cache + LRU Cache    │
             │ 4. Local-first playback pipeline via AVFoundation│
             └──────────────────────────────────────────────────┘
```

### The Top-Line Verdict

1. **The "Storage Problem" is Smaller Than Expected**: A common misconception is that 100 audio files consume hundreds of megabytes. Because Cooltour stories are short spoken-word narrations (45–90 seconds), properly encoded audio (HE-AAC / AAC-LC @ 32–48 kbps mono) requires only **~250 KB per story**. A full library of **100 sites consumes only ~25 MB**—smaller than a single modern social media video.
2. **Pure Online Streaming is an Anti-Pattern for Proximity Walking Apps**: Streaming audio on-demand (e.g. from Supabase / S3) when entering a 30m geofence causes a **2 to 5-second buffering delay**, cellular handshake failures in stone alleys/temples, and breaks completely in airplane mode or with spotty tourist eSIMs. The user walks past the POI before the audio starts, pulling out their phone in confusion—violating the **Screen-Free Attention Test**.
3. **The Recommended Architecture: 3-Phase Scalable Strategy**:
   - **Phase 1 (Current / exhibition — 10–50 sites in Denpasar + walk tests)**: **Bundled Regional Content Pack**. 100% offline, zero latency, ~10 MB storage. **Ship this for the show.**
   - **Phase 2 (Growth / 50–200 sites across Bali / 3–5 cities)**: **On-Demand Regional Packs** — **deferred post-exhibition** (see [`RegionalPacksSlice.md`](RegionalPacksSlice.md)). Download city packs over Wi-Fi into App Support when multi-city scale returns.
   - **Phase 3 (Scale / 1,000+ pins / Global Free-Roam)**: **Predictive Geofenced Pre-fetching + LRU Cache**. Store lightweight metadata on device; transparently pre-cache the nearest 15 POIs into a bounded 50 MB local cache when entering a 2 km district geofence.

---

## 2. Storage & Codec Calculations (The Real Math)

Voice narration does not need stereo 320 kbps studio music bitrates. Human speech is mono, concentrated between 80 Hz and 8 kHz, and compresses extremely well with Apple's native hardware AAC decoder.

### Codec Comparison for 60-Second Spoken Word

| Format & Bitrate | Audio Quality for Narration | File Size (1 min) | 50 Sites (50 min) | 100 Sites (100 min) | 1,000 Sites (1,000 min) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Uncompressed WAV (16-bit 44.1kHz stereo)** | Studio raw (Wasteful) | ~10.5 MB | 525 MB | 1.05 GB | 10.5 GB |
| **Standard MP3 @ 128 kbps stereo** | Legacy baseline | ~960 KB | 48 MB | 96 MB | 960 MB |
| **AAC-LC @ 64 kbps mono** | High clarity voice | ~480 KB | 24 MB | 48 MB | 480 MB |
| **AAC-LC @ 48 kbps mono (24kHz)** | **Recommended standard** | **~360 KB** | **18 MB** | **36 MB** | **360 MB** |
| **HE-AAC v2 @ 32 kbps mono (32kHz)** | **Ultra-compact crisp speech** | **~240 KB** | **12 MB** | **24 MB** | **240 MB** |
| **xHE-AAC / Opus @ 24 kbps** | Efficient, minimal size | ~180 KB | 9 MB | 18 MB | 180 MB |

> **Key Insight**: At **32–48 kbps AAC**, 100 stories take **only 24–36 MB**. This is negligible on modern iPhones with 128 GB–1 TB storage. Storage only becomes a constraint when scaling to multiple global cities (500+ locations), which is solved by modular regional packs.

---

## 3. Comprehensive Evaluation of the 4 Approaches

```
[Approach 1: Bundled Assets]   --> 0ms Latency, 100% Offline, Zero Cloud Cost. Fixed in App Bundle.
[Approach 2: Pure Streaming]    --> 0MB Init Storage, 2-5s Lag, Breaks in Dead Zones, High Egress.
[Approach 3: Regional Packs]    --> 0ms Latency, Offline per City, Download over Wi-Fi, Modular.
[Approach 4: Predictive Cache]  --> Invisible Pre-fetch, Bounded 50MB Disk Cache, 0ms Proximity.
```

### Deep-Dive Trade-off Matrix

| Evaluation Criteria | Approach 1: Bundled in App | Approach 2: Pure Remote Streaming (Supabase/S3) | Approach 3: Regional Download Packs | Approach 4: Predictive LRU Cache + Geofence |
| :--- | :--- | :--- | :--- | :--- |
| **Trigger Latency** | **0 ms** (Instant) | **2,000 – 5,000 ms** (High delay) | **0 ms** (Instant once pack is downloaded) | **0 ms** (Pre-cached before user arrives) |
| **Offline Reliability** | **100%** (Works in Airplane Mode) | **0%** (Fails without active data connection) | **100%** (Full offline walk) | **95%** (Prefetched in background; offline once near) |
| **Storage Impact (100 POIs)** | ~25 MB in app binary | 0 MB initially (stalls on playback) | ~25 MB per city (user can delete) | Capped at ~30–50 MB max dynamically |
| **Attention Test Compatibility** | **Passes** (Screen stays in pocket) | **Fails** (User checks screen when audio lags) | **Passes** (Seamless walk once downloaded) | **Passes** (Transparent background prefetch) |
| **Background / Lock-Screen Playback** | **Rock-solid** (`AVAudioPlayer` local) | **Fragile** (iOS background network timeouts) | **Rock-solid** (`AVAudioPlayer` local) | **Rock-solid** (`AVAudioPlayer` local) |
| **Server / Egress Cost** | **$0** (Hosted via Apple App Store CDN) | **High** (Repeated egress fees on Supabase/AWS) | **Low** (Batch downloaded once per tour) | **Low/Medium** (Prefetches nearest 15 clips only) |
| **OTA Content Updates** | Requires App Store update | Instant (Change audio URL in database) | Instant (Increment pack version number) | Instant (Server manifest update) |
| **Battery Consumption** | **Lowest** (Local SSD read only) | **Highest** (Cellular radio wakes on every trigger) | **Lowest** during walk | **Low** (Batched prefetch on Wi-Fi/coarse entry) |

---

## 4. Why Pure Real-Time Streaming Fails for Cooltour

### 1. The Proximity Window Problem (Walking Speed Math)
- Normal human walking speed = **1.3 m/s** (~4.7 km/h).
- Trigger radius for dense cultural sites (e.g. *Pura Jagatnatha* or *Pasar Badung*) = **35 meters**.
- A user walks across the 35m trigger radius in **~27 seconds**.
- If direct streaming requires DNS, TLS, TTFB, and audio buffering (total 2.5s–5.0s delay), the user has already walked 6–8 meters past the entrance or turned a corner before the voice starts speaking: *"Look at the red brick in front of you..."* The illusion of magic is broken.

### 2. The Cultural Tourism Signal Reality
- Sites like Pasar Badung (dense multi-story concrete indoor market) or Pura Maospahit (thick brick perimeter walls) are **cellular signal dead zones**.
- International travelers frequently use roaming eSIMs with throttled 3G/LTE speeds, or keep phones in Airplane Mode to save roaming data/battery.
- Streaming introduces audio stuttering, mid-sentence dropouts, or complete silence.

### 3. iOS Lock Screen & Background Energy Throttling
- When the iPhone is in the pocket with the screen locked, iOS aggressively suspends background network requests after a few seconds.
- Waking up a cellular radio to initiate an HTTP stream from a background `CLMonitor` wake has high failure rates compared to playing a local file via `AVAudioPlayer` with an active `.playback` audio session.

---

## 5. The Recommended Architecture for Cooltour

To provide the ultimate user experience while keeping storage lean and server costs near zero, we implement a **Local-First Audio Pipeline** with **Layered Content Resolution**.

```
                           AUDIO RESOLUTION PIPELINE
                           
                   ProximityEngine triggers Site & Story
                                     │
                                     ▼
                      AudioResourceResolver.resolve(story)
                                     │
                 ┌───────────────────┴───────────────────┐
                 │                                       │
                 ▼                                       ▼
        [1. Check App Bundle]                 [2. Check Local Cache / Pack]
        Bundle.main.url(...)                  FileManager ApplicationSupport/Caches
                 │                                       │
                 ├─ Found ──► Return local URL           ├─ Found ──► Return local URL
                 │                                       │
                 └─ Not Found                            └─ Not Found
                                                                 │
                                                                 ▼
                                                      [3. Background Prefetch]
                                                      Download from CDN to Cache
                                                      (or fallback stream if online)
                                                                 │
                                                                 ▼
                                                      AVAudioPlayerService.play(url)
                                                      (ALWAYS plays from local file)
```

---

## 6. Phased Implementation Roadmap

### Phase 1: MVP Optimization (Current Status — exhibition path)
- **Action**: Keep the Denpasar (and walk-test) content pack **bundled locally**. No download step for the demo.
- **Audio Optimization**: Transcode all audio files to **AAC-LC @ 48 kbps mono** (or **HE-AAC @ 32 kbps mono**).
- **Result**: Entire Denpasar tour with 20–30 sites is **under 6 MB total**. Zero architectural bloat, 100% offline compliance for ADA review / exhibition.

### Phase 2: Regional Content Packs (Multi-City Expansion) — **DEFERRED**
- **Status (2026-08-20):** Parked until **after the exhibition**. Priority is back-of-queue. Demo ships Phase 1 (in-app audio only).
- **Build spec (when resumed):** [`documents/RegionalPacksSlice.md`](RegionalPacksSlice.md) — city zips on Cloudflare R2, Denpasar stays bundled, Settings download/delete, city-geofence notification. No streaming.
- **Action**: Separate content by regions (e.g. *Denpasar.json + audio*, *Ubud.json + audio*, *Sanur.json + audio*).
- **Storage Backend**: Store zipped packs in **Cloudflare R2** behind a public `catalog.json`. (Supabase is an editorial CMS later, not the playback path.)
- **Settings UI**: Add a **"Downloaded Content"** section in `SettingsView` where users can view installed city packs (e.g., "Denpasar Heritage: 12.4 MB") and download/delete the others.

### Phase 3: Autonomous Predictive Smart-Cache (Global Free Roam)
- **Action**: Integrate `CLMonitor` district geofences (1.5 km – 3 km radius). Still after Phase 2.
- **Background Pipeline**: As user moves, silently download the next 10 POIs ahead of time using `URLSessionConfiguration.background`.
- **Playback**: Seamless, invisible, bounded at 50 MB storage forever.

---

## 7. Production Audio Pipeline & Transcoding Guide

To achieve maximum compression without voice distortion, use this standard FFmpeg command for all Kultara guide audio recordings:

```bash
# Recommended FFmpeg preset for voice narration (Cooltour standard):
ffmpeg -i raw_guide_recording.wav \
  -c:a aac -b:a 40k -ar 32000 -ac 1 \
  -movflags +faststart \
  optimized_story.m4a
```

**Parameters Explained**:
- `-c:a aac`: Native Apple-compatible Advanced Audio Codec.
- `-b:a 40k`: 40 kbps bitrate (sweet spot for crystal-clear voice and minimal file size).
- `-ar 32000`: 32 kHz sample rate (captures all human speech harmonics up to 16 kHz).
- `-ac 1`: Mono channel (narrator voice is single-source, cuts file size in half).
- `-movflags +faststart`: Places the MP4/M4A `moov` atom at the front of the file for instant seeking and reading.
