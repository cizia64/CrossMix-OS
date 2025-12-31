#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/ppsspp_setup"

if [ ! -d "$SETUP_DIR" ]; then
  echo "Missing setup directory: $SETUP_DIR"
  exit 1
fi

ROOT_DIR="$SCRIPT_DIR"
for _ in 1 2 3 4 5 6; do
  if [ -d "$ROOT_DIR/Emus" ] && [ -d "$ROOT_DIR/Roms" ]; then
    break
  fi
  if [ "$ROOT_DIR" = "/" ]; then
    break
  fi
  ROOT_DIR="$(dirname "$ROOT_DIR")"
done

if [ ! -d "$ROOT_DIR/Emus" ]; then
  echo "Could not locate SD root (missing Emus folder)."
  exit 1
fi

ROM_DIR="$ROOT_DIR/Roms/PSP"
if [ ! -d "$ROM_DIR" ]; then
  echo "Missing ROM folder: $ROM_DIR"
  exit 1
fi

DEVICE_ROM_DIR="/mnt/SDCARD/Roms/PSP"
if [ "$ROM_DIR" != "$DEVICE_ROM_DIR" ]; then
  echo "Skipping CurrentDirectory update (expected $DEVICE_ROM_DIR, got $ROM_DIR)."
  UPDATE_CURRENT_DIR=0
else
  UPDATE_CURRENT_DIR=1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found."
  exit 1
fi

find_python() {
  host_python3="$(command -v python3 || true)"
  host_python="$(command -v python || true)"
  for candidate in "$host_python3" "$host_python" "$ROOT_DIR/System/bin/python3"; do
    [ -n "$candidate" ] || continue
    if "$candidate" -c 'import sys' >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PYTHON="$(find_python || true)"
if [ -z "$PYTHON" ]; then
  echo "Python not found."
  exit 1
fi

REDUMP_URL="https://raw.githubusercontent.com/hrydgard/ppsspp/master/assets/redump.csv"

echo
echo "Step 1/5: Downloading redump.csv..."
curl -L -o "$SETUP_DIR/psp_redump.csv" "$REDUMP_URL" || exit 1

echo
echo "Step 2/5: Generating PSP game IDs..."
"$PYTHON" "$SETUP_DIR/psp_game_ids_from_redump.py" || exit 1

echo
echo "Step 3/5: Generating PPSSPP settings CSV..."
"$PYTHON" "$SETUP_DIR/ppsspp_generate_settings_csv.py" || exit 1

echo
echo "Step 4/5: Applying settings to PPSSPP installs..."
"$PYTHON" "$SETUP_DIR/ppsspp_apply_game_settings.py" || exit 1

echo
echo "Step 5/5: Updating PPSSPP configs..."
if [ -d "$ROOT_DIR/Emus/PSP" ]; then
  for ppsspp_dir in "$ROOT_DIR/Emus/PSP"/PPSSPP_*; do
    [ -d "$ppsspp_dir" ] || continue
    psp_dir="$ppsspp_dir/.config/ppsspp/PSP"
    system_dir="$psp_dir/SYSTEM"
    ini="$system_dir/ppsspp.ini"

    mkdir -p "$system_dir"

    if [ -f "$ini" ] && [ "$UPDATE_CURRENT_DIR" -eq 1 ]; then
      "$PYTHON" - "$ini" "$ROM_DIR" <<'PYCODE'
import sys
from pathlib import Path

ini_path = Path(sys.argv[1])
rom_dir = sys.argv[2]

lines = ini_path.read_text(encoding="utf-8", errors="ignore").splitlines()
out = []
found = False
for line in lines:
    if line.strip().startswith("CurrentDirectory"):
        out.append(f"CurrentDirectory = {rom_dir}")
        found = True
    else:
        out.append(line)
if not found:
    out.append(f"CurrentDirectory = {rom_dir}")

ini_path.write_text("\n".join(out) + "\n", encoding="utf-8")
PYCODE
    fi
  done
fi

echo "Done."
