#!/bin/zsh
# Cooltour Audio Optimization Script
# Converts raw audio takes into normalized, lightweight 40kbps mono AAC files.
# to run the batch optimizer on any folder of recorded voice takes:
# [copy and run this line] ./scripts/optimize_audio.sh path/to/raw_recordings Cooltour/Resources/Audio

set -e

# Ensure ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Error: FFmpeg is required. Install it via Homebrew:"
    echo "  brew install ffmpeg"
    exit 1
fi

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./optimized_audio}"

mkdir -p "$OUTPUT_DIR"

echo "=== Cooltour Audio Optimizer ==="
echo "Input Directory:  $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Target Format:    Mono AAC @ 40kbps, 32kHz, -16 LUFS normalized"
echo "================================="

count=0
for file in "$INPUT_DIR"/*.{wav,m4a,mp3,caf,aif,aiff,WAV,M4A}; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    slug="${filename%.*}"
    
    # Skip already optimized output directory if in current folder
    if [[ "$file" == *"optimized_audio"* ]]; then
        continue
    fi

    echo "▶ Processing: $filename -> $OUTPUT_DIR/${slug}.m4a"
    
    # Audio filters:
    # 1. highpass=f=80: Removes low-end handling noise and rumble below 80Hz
    # 2. loudnorm=I=-16:TP=-1.5:LRA=11: Normalizes speech to standard podcast loudness (-16 LUFS)
    # 3. -ac 1: Converts to mono
    # 4. -ar 32000: Resamples to 32kHz (sufficient for voice up to 16kHz)
    # 5. -b:a 40k: High efficiency 40kbps AAC
    # 6. -movflags +faststart: Places the MP4 moov atom at the front for instant seeking
    ffmpeg -y -v warning -i "$file" \
        -af "highpass=f=80,loudnorm=I=-16:TP=-1.5:LRA=11" \
        -c:a aac -b:a 40k -ar 32000 -ac 1 \
        -movflags +faststart \
        "$OUTPUT_DIR/${slug}.m4a"
    
    ((count++))
done

if [ $count -eq 0 ]; then
    echo "ℹ️ No audio files (.wav, .m4a, .mp3, .caf) found in '$INPUT_DIR'."
    echo "Usage: ./scripts/optimize_audio.sh [input_directory] [output_directory]"
else
    echo "================================="
    echo "✅ Successfully optimized $count audio files in '$OUTPUT_DIR'."
    echo "👉 Copy these files to 'Cooltour/Resources/Audio/' and check 'Cooltour/Resources/denpasar.json'."
fi
