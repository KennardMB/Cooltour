#!/usr/bin/env python3
"""Generate placeholder narration from the content pack transcripts.

The JSON is the single source of truth: this reads each transcript, speaks it with
macOS `say`, and writes the measured duration back into the pack. Throw the generated
.m4a files away once real Kultara recordings land.

    python3 tools/make-placeholder-audio.py
"""

import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACK = ROOT / "Cooltour" / "Resources" / "denpasar.json"
AUDIO_DIR = ROOT / "Cooltour" / "Resources" / "Audio"
VOICE = "Daniel"


def duration_of(path):
    out = subprocess.run(["afinfo", str(path)], capture_output=True, text=True).stdout
    match = re.search(r"estimated duration: ([\d.]+) sec", out)
    if not match:
        sys.exit(f"could not read duration from {path}")
    return round(float(match.group(1)), 1)


def main():
    pack = json.loads(PACK.read_text())
    AUDIO_DIR.mkdir(parents=True, exist_ok=True)

    for site in pack["sites"]:
        for story in site["stories"]:
            target = AUDIO_DIR / story["audioFile"]
            spoken = story["transcript"].replace("\n", " ")
            subprocess.run(
                ["say", "-v", VOICE, "-o", str(target), "--data-format=aac", spoken],
                check=True,
            )
            story["durationSeconds"] = duration_of(target)
            print(f"{target.name}  {story['durationSeconds']}s")

    PACK.write_text(json.dumps(pack, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
