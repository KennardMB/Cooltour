# Audio Recording & Production Guide
**App:** Cooltour (*Codename: Nyasar*)  
**Audience:** Team Cooltour / Storytellers / Apple Developer Academy Contributors  
**Related Docs:** [`documents/AudioArchitectureAnalysis.md`](AudioArchitectureAnalysis.md), [`documents/InitialCooltour.md`](InitialCooltour.md), [`AGENTS.md`](../AGENTS.md)  

---

## 1. The Core Philosophy: Authentic Human Storytelling

Cooltour relies on **human-recorded voice narration**, not synthetic AI/Siri text-to-speech. The narration should feel like a **local friend walking beside the user**, pointing out details they would otherwise miss.

### The Golden Production Rule
> **Capture in Lossless Master Quality $\rightarrow$ Batch Export to Lightweight Mono Distribution.**
>
> Never record in low quality or compressed mono directly at capture time. Always record in uncompressed/lossless audio (WAV or Lossless Apple Voice Memos) with proper mic technique, then run the automated conversion script to export the final files into **mono 40 kbps `.m4a`** for the app.

---

## 2. Equipment & Acoustic Setup (Zero Cost / Academy Friendly)

You do not need an expensive recording studio. An iPhone microphone is a studio-grade MEMS condenser microphone. However, **room acoustics and microphone positioning account for 90% of the audio quality**.

### A. The Recording Environment (The "Closet Method")
* **Eliminate Reverb / Echo**: Hard surfaces (glass windows, tiles, empty drywall) create boxy reflections that sound amateur and fatigue the listener's ears.
* **Best Free Acoustic Spaces**:
  * **Clothes Wardrobe / Closet**: Hanging clothes naturally absorb reflections across all voice frequencies.
  * **The Blanket / Cushion Tent**: Sitting under a soft blanket or speaking with sofa cushions placed on both sides of the phone creates a dry, broadcast-like vocal tone.
  * **Turn off AC, fans, and close windows** for the 2–3 minutes needed for each recording take.

### B. Microphone Selection

| Hardware | Rating | Notes |
| :--- | :--- | :--- |
| **iPhone Bottom Built-in Microphone** | ⭐⭐⭐⭐⭐ **Best Free Option** | Clean frequency response, low self-noise, natural warmth. |
| **USB / XLR Condenser Mic (Mac)** | ⭐⭐⭐⭐⭐ **Best if Available** | E.g. Rode NT-USB, Blue Yeti, Shure MV7, Audio-Technica AT2020. |
| **Wired EarPods (Lightning / USB-C)** | ⭐⭐⭐ **Acceptable** | Secure the wire with a clip to prevent clothing friction rustle. |
| **AirPods / Bluetooth Earbuds** | ❌ **Avoid for Masters** | Bluetooth Hands-Free Profile (HFP) compresses audio to 16 kHz, sounding muffled and like a phone call. |

### C. Microphone Positioning & Plosive Prevention
* **Distance**: Hold the iPhone **15–20 cm (6–8 inches)** from your mouth.
* **The 45-Degree Angle (Off-Axis Technique)**: Do **not** point the bottom microphone directly at your mouth. Hold the phone slightly below your chin angled upwards toward your nose. This allows air blasts from "P", "B", and "T" sounds to blow past the capsule rather than creating low-end "pops" (plosives).

```
          [ Speaker's Mouth ]
                  │
             (Air blast goes straight) ──► 💨
                  │
                  ▼  (45° off-axis)
             📱 [ iPhone Bottom Mic ]
```

---

## 3. Recording Apps & Device Settings

### Option A: Apple Voice Memos (Recommended & Built-In)
1. Open iOS **Settings** $\rightarrow$ **Voice Memos**.
2. Set **Audio Quality** to **Lossless** (Change from default *Compressed*).
3. Open the **Voice Memos** app and record your story take.
4. *(Optional)* Tap the **Options icon (slider lines)** on the recording $\rightarrow$ test toggling **Enhance Recording** to check if it cleans minor room background noise.
5. AirDrop the file to your Mac (it exports as a clean `.m4a` / Apple Lossless file).

### Option B: Ferrite or Shure MOTIV Audio (Advanced iOS Control)
* Apps like **Ferrite Recording Studio** or **Shure MOTIV Audio** (both free on the App Store) allow recording directly in **24-bit 48 kHz uncompressed WAV**.

---

## 4. Voice Direction, Pacing & Story Structure

### Cultural Walking Tour Voice Style (Kultara Inspired)
* **Tone**: Warm, intimate, observational. Speak as if talking to one person walking next to you.
* **Pacing**: Aim for **120–140 words per minute** (about 15% slower than normal conversation). Walkers are taking in visual surroundings while listening.
* **Sentence Length**: Keep sentences short and clear. Avoid nested subordinate clauses.
* **Orientation Anchors**: Always ground the listener visually within the first 5–10 seconds:
  * *“Look at the red brick in front of you...”*
  * *“Notice the empty seat at the top of the throne...”*
  * *“Look up above the archway...”*
* **Target Duration**: **45 to 75 seconds** ($\sim 100\text{–}160\text{ words}$). Narrations exceeding 90 seconds cause cognitive overload during an active walk.

---

## 5. Automated Post-Processing & Master-to-App Conversion

Once raw recordings are transferred to a Mac, they must be normalized, high-pass filtered, and encoded to the app's target format: **mono 40 kbps AAC (`.m4a`)**.

### Automated Mac Conversion Script

Save this script as `scripts/optimize_audio.sh` in the repo, or run it in your working audio folder:

```bash
#!/bin/zsh
# Cooltour Audio Optimization Script
# Converts raw audio takes into normalized, lightweight 40kbps mono AAC files.

set -e

# Ensure ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "FFmpeg is required. Install via Homebrew: brew install ffmpeg"
    exit 1
fi

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./optimized_audio}"

mkdir -p "$OUTPUT_DIR"

echo "=== Optimizing audio files in $INPUT_DIR ==="

for file in "$INPUT_DIR"/*.{wav,m4a,mp3,caf,aif}; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    slug="${filename%.*}"
    
    echo "Processing: $filename -> $OUTPUT_DIR/${slug}.m4a"
    
    # Audio filters applied:
    # 1. highpass=f=80: Removes sub-80Hz handling rumble, wind, and room resonance.
    # 2. loudnorm=I=-16:TP=-1.5:LRA=11: Normalizes speech to standard podcast loudness (-16 LUFS).
    # 3. -ac 1: Converts stereo to mono (narrator voice is single source).
    # 4. -ar 32000: Resamples to 32kHz (sufficient for voice up to 16kHz).
    # 5. -b:a 40k: High-efficiency 40 kbps AAC encoding.
    # 6. -movflags +faststart: Places the MP4 moov atom at the beginning for instant seeking.
    ffmpeg -y -i "$file" \
        -af "highpass=f=80,loudnorm=I=-16:TP=-1.5:LRA=11" \
        -c:a aac -b:a 40k -ar 32000 -ac 1 \
        -movflags +faststart \
        "$OUTPUT_DIR/${slug}.m4a"
done

echo "✅ Optimization complete. Files saved in $OUTPUT_DIR"
```

---

## 6. Production Workflow Checklist

```
[1. Script Writing]     --> 100-150 words (45-75s) with physical orientation cues
          ↓
[2. Lossless Record]    --> iPhone Voice Memos (Lossless) in wardrobe/cushion tent (15-20cm off-axis)
          ↓
[3. AirDrop to Mac]     --> Transfer raw recordings to Mac
          ↓
[4. Run Batch Script]   --> Run ./scripts/optimize_audio.sh (Filter 80Hz + Normalize -16 LUFS + Mono 40k AAC)
          ↓
[5. Place in App]       --> Copy .m4a files to Cooltour/Resources/Audio/
          ↓
[6. Update JSON]        --> Verify audioFile name matches in Cooltour/Resources/denpasar.json
```

- [ ] Voice Memos set to **Lossless** in iOS Settings.
- [ ] Recorded in a treated/soft acoustic space (closet/cushions, AC off).
- [ ] Distance 15–20 cm, angled 45° below chin to prevent plosives.
- [ ] Pacing relaxed (~130 wpm), story duration 45–75 seconds.
- [ ] Converted to **mono 40 kbps AAC** via FFmpeg script.
- [ ] File placed in [`Cooltour/Resources/Audio/`](../Cooltour/Resources/Audio/) with matching slug in [`Cooltour/Resources/denpasar.json`](../Cooltour/Resources/denpasar.json).
