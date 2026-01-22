#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/.ppsspp_setup"

INFOSCREEN="/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh"
show_step() {
  message="$1"
  if [ -x "$INFOSCREEN" ]; then
    "$INFOSCREEN" -m "$message" -t 1
  fi
}
show_error() {
  message="$1"
  echo "ERROR: $message" >&2
  if [ -x "$INFOSCREEN" ]; then
    "$INFOSCREEN" -m "$message" -c red -t 4
  fi
}
die() {
  message="$1"
  code="${2:-1}"
  show_error "$message"
  exit "$code"
}

if [ ! -d "$SETUP_DIR" ]; then
  die "Missing setup directory: $SETUP_DIR"
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
echo "Root directory: $ROOT_DIR"

if [ ! -d "$ROOT_DIR/Emus" ]; then
  die "Could not locate SD root (missing Emus folder)."
fi

download_file() {
  url="$1"
  out="$2"
  curl_bin=""
  wget_bin=""

  if command -v wget >/dev/null 2>&1; then
    wget_bin="wget"
  elif [ -x "$ROOT_DIR/System/bin/wget" ]; then
    wget_bin="$ROOT_DIR/System/bin/wget"
  fi

  if command -v curl >/dev/null 2>&1; then
    curl_bin="curl"
  elif [ -x "$ROOT_DIR/System/bin/curl-aarch64" ]; then
    curl_bin="$ROOT_DIR/System/bin/curl-aarch64"
  fi

  if [ -n "$wget_bin" ]; then
    "$wget_bin" --no-check-certificate -O "$out" "$url"
    return $?
  fi
  if [ -n "$curl_bin" ]; then
    "$curl_bin" -k -L -o "$out" "$url"
    return $?
  fi
  return 127
}

ROM_DIR="$ROOT_DIR/Roms/PSP"
if [ ! -d "$ROM_DIR" ]; then
  die "Missing ROM folder: $ROM_DIR"
fi

DEVICE_ROM_DIR="/mnt/SDCARD/Roms/PSP"
ALT_ROM_DIR="$ROOT_DIR/Roms/PSP"
CURRENT_DIR=""
if [ -d "$DEVICE_ROM_DIR" ]; then
  CURRENT_DIR="$DEVICE_ROM_DIR"
elif [ -d "$ALT_ROM_DIR" ]; then
  CURRENT_DIR="$ALT_ROM_DIR"
else
  die "Could not locate PSP ROMs directory."
fi
echo "ROMs directory found in $CURRENT_DIR"

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
  die "Python not found."
fi

REDUMP_URL="https://raw.githubusercontent.com/hrydgard/ppsspp/master/assets/redump.csv"

echo
echo "Step 1/5: Fetching PSP games database..."
show_step "Step 1/5: Fetching PSP games database..."
if ! download_file "$REDUMP_URL" "$SETUP_DIR/psp_redump.csv"; then
  if [ -s "$SETUP_DIR/psp_redump.csv" ]; then
    echo "Download failed; using local CSV fallback."
  else
    die "Download failed and no local CSV fallback has been found."
  fi
fi

echo
echo "Step 2/5: Building PSP game ID list..."
show_step "Step 2/5: Building PSP game ID list..."
if ! "$PYTHON" "$SETUP_DIR/psp_game_ids_from_redump.py"; then
  die "Step 2/5 failed: could not generate PSP game IDs."
fi

echo
echo "Step 3/5: Building PPSSPP per-game settings..."
show_step "Step 3/5: Building PPSSPP per-game settings..."
if ! "$PYTHON" "$SETUP_DIR/ppsspp_generate_settings_csv.py"; then
  die "Step 3/5 failed: could not generate PPSSPP settings CSV."
fi

echo
echo "Step 4/5: Writing per-game configs to PPSSPP..."
show_step "Step 4/5: Writing per-game configs to PPSSPP..."
if ! "$PYTHON" "$SETUP_DIR/ppsspp_apply_game_settings.py"; then
  die "Step 4/5 failed: could not apply PPSSPP game settings."
fi

echo
echo "Step 5/5: Updating PPSSPP ROM path..."
show_step "Step 5/5: Updating PPSSPP ROM path..."
if [ -d "$ROOT_DIR/Emus/PSP" ]; then
  for ppsspp_dir in "$ROOT_DIR/Emus/PSP"/PPSSPP_*; do
    [ -d "$ppsspp_dir" ] || continue
    psp_dir="$ppsspp_dir/.config/ppsspp/PSP"
    system_dir="$psp_dir/SYSTEM"
    ini="$system_dir/ppsspp.ini"

    mkdir -p "$system_dir"

    if [ -f "$ini" ]; then
      "$PYTHON" - "$ini" "$CURRENT_DIR" <<'PYCODE'
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
