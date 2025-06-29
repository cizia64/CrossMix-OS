#!/usr/bin/env python3
#M3U Playlist generator by Cizia for CrossMix.

import os
import re
import shutil
import sys
from pathlib import Path
from collections import defaultdict

VALID_EXTENSIONS = {".chd", ".bin", ".cue", ".iso", ".img"}

# Regex to match disc number
DISC_REGEX = re.compile(
    r"""(?ix)
    (.*?)                     # Group 1: game name
    \s*
    [\(\[]                    # Opening ( or [
    (?:Disc|Disk)             # "Disc" or "Disk"
    \s*(\d+)                  # Disc number
    (?:\s*of\s*\d+)?          # Optional "of N"
    [\)\]]                    # Closing ) or ]
    [^/\\]*$                  # End of string
""")

# Regex to remove tags like [SLES-xxxxx]
SLES_TAG_REGEX = re.compile(r"\s*\[[A-Z]{4}-[^\]]+\]", re.IGNORECASE)

def usage():
    print("Usage:")
    print("  python3 script.py -md|-sd <roms_path>")
    sys.exit(1)

# ─── Parse arguments ───
if len(sys.argv) != 3 or sys.argv[1] not in ("-md", "-sd"):
    usage()

mode = sys.argv[1]
roms_dir = Path(sys.argv[2]).resolve()
imgs_dir = Path(f"/mnt/SDCARD/Imgs/{roms_dir.name}")
output_base = roms_dir / (".multi-disc" if mode == "-sd" else "")

if not roms_dir.exists():
    print(f"❌ Directory not found: {roms_dir}")
    sys.exit(1)

roms = defaultdict(list)
total_created = 0

# ─── Scan ROM files ───
print(f"🔍 Scanning ROMs in: {roms_dir}")
for entry in os.listdir(roms_dir):
    full_path = roms_dir / entry
    if not full_path.is_file():
        continue
    ext = full_path.suffix.lower()
    if ext not in VALID_EXTENSIONS:
        continue

    stem = full_path.stem
    match = DISC_REGEX.match(stem)
    if match:
        raw_base = match.group(1).strip()
        cleaned_base = SLES_TAG_REGEX.sub("", raw_base).strip()
        roms[cleaned_base].append(entry)

# ─── Process matched games ───
for base_name, files in roms.items():
    sorted_files = sorted(
        files,
        key=lambda f: int(re.search(r"[\[\(][Dd][Ii][Ss][KkCc]\s*(\d+)", f).group(1))
        if re.search(r"[\[\(][Dd][Ii][Ss][KkCc]\s*(\d+)", f) else 0
    )

    if mode == "-md":
        target_folder = roms_dir / f".{base_name}"
        m3u_path = roms_dir / f"{base_name}.m3u"
    else:
        target_folder = output_base
        m3u_path = roms_dir / f"{base_name}.m3u"

    # Create folder if needed
    target_folder.mkdir(exist_ok=True)
    print(f"\n📁 Processing: {base_name}")
    print(f"   → Target folder: {target_folder.relative_to(roms_dir)}")

    # Create M3U playlist
    print(f"   → Creating playlist: {m3u_path.name}")
    with open(m3u_path, "w", encoding="utf-8") as m3u_file:
        for f in sorted_files:
            src = roms_dir / f
            dest = target_folder / f
            if src != dest:
                print(f"   → Moving: {f} → {dest.relative_to(roms_dir)}")
                shutil.move(str(src), str(dest))
            m3u_file.write(f"./{dest.relative_to(m3u_path.parent)}\n")

    # Try to copy matching PNG
    for f in sorted_files:
        image_src = imgs_dir / f"{Path(f).stem}.png"
        if image_src.exists():
            image_dest = imgs_dir / f"{base_name}.png"
            print(f"🖼️  Copying image: {image_src.name} → {image_dest.name}")
            shutil.copy(image_src, image_dest)
            break

    total_created += 1

# ─── Final log ───
print(f"\n✅ Total M3U playlists created: {total_created}")
print(f"TOTAL_M3U_CREATED={total_created}")
