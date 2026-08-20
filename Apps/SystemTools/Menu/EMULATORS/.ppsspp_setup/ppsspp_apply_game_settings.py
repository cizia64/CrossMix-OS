#!/usr/bin/env python3
from __future__ import annotations

import csv
import re
import sys
from configparser import ConfigParser, MissingSectionHeaderError
from io import StringIO
from pathlib import Path

KEY_SECTION = {
    "InternalResolution": "Graphics",
    "GraphicsBackend": "Graphics",
    "SkipBufferEffects": "Graphics",
    "AnisotropyLevel": "Graphics",
    "TextureBackoffCache": "Graphics",
    "SplineBezierQuality": "Graphics",
    "SkipGPUReadbacks": "Graphics",
    "FrameSkip": "Graphics",
    "AutoFrameSkip": "Graphics",
    "TexScalingType": "Graphics",
    "TexScalingLevel": "Graphics",
    "CPUSpeed": "CPU",
}

HEADER_RE = re.compile(r"^#\s*Game config for\s+([A-Z0-9]{4}\d{5})\s*-\s*(.+)$", re.I)


def normalize_title(title: str) -> str:
    title = title.lower()
    title = re.sub(r"\(.*?\)", " ", title)
    title = re.sub(r"\[.*?\]", " ", title)
    title = re.sub(r"[^a-z0-9]+", " ", title)
    return re.sub(r"\s+", " ", title).strip()


def best_game_row(game_rows, title):
    if not title:
        return None
    key = normalize_title(title)
    return game_rows.get(key)


def resolve_root(script_dir: Path) -> Path:
    root = script_dir
    emus_root = None
    for _ in range(6):
        if (root / "Emus").is_dir():
            if emus_root is None:
                emus_root = root
            if (root / "Roms").is_dir():
                return root
        if root.parent == root:
            break
        root = root.parent
    return emus_root or script_dir


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    root_dir = resolve_root(script_dir)
    settings_csv = Path(sys.argv[1]) if len(sys.argv) > 1 else script_dir / "ppsspp_game_settings.csv"

    if not settings_csv.is_file():
        print(f"Missing settings CSV: {settings_csv}", file=sys.stderr)
        return 1

    ppsspp_base = root_dir / "Emus" / "PSP"
    if ppsspp_base.is_dir():
        ppsspp_dirs = sorted(path for path in ppsspp_base.glob("PPSSPP_*") if path.is_dir())
    else:
        ppsspp_dirs = []
    if not ppsspp_dirs:
        print("No PPSSPP_* directories found.", file=sys.stderr)
        return 1

    with settings_csv.open("r", encoding="utf-8", errors="ignore", newline="") as f:
        rows = list(csv.DictReader(f))

    id_rows = {}
    game_rows = {}
    for row in rows:
        game_id = (row.get("GameID") or "").strip().upper()
        if game_id:
            id_rows[game_id] = row
        game_name = (row.get("Game") or "").strip()
        if not game_name:
            continue
        key = normalize_title(game_name)
        if not key:
            continue
        score_raw = (row.get("MatchScore") or "").strip()
        try:
            score = float(score_raw)
        except ValueError:
            score = 0.0
        existing = game_rows.get(key)
        if existing is None or score > float(existing.get("MatchScore") or 0):
            game_rows[key] = row

    def apply_row(row, pdir):
        game_id = (row.get("GameID") or "").strip().upper()
        if not game_id:
            return False
        system_dir = pdir / ".config" / "ppsspp" / "PSP" / "SYSTEM"
        base_ini = system_dir / "ppsspp.ini"
        primary_ini = system_dir / f"{game_id}_ppsspp.ini"
        legacy_ini = system_dir / f"{game_id}.ini"

        cfg = ConfigParser(interpolation=None)
        cfg.optionxform = str
        for src in (base_ini, primary_ini, legacy_ini):
            if not src.is_file():
                continue
            try:
                with src.open("r", encoding="utf-8-sig", errors="strict") as f:
                    cfg.read_file(f)
            except MissingSectionHeaderError:
                continue

        for key, section in KEY_SECTION.items():
            val = (row.get(key) or "").strip()
            if not val:
                continue
            if not cfg.has_section(section):
                cfg.add_section(section)
            cfg.set(section, key, val)

        system_dir.mkdir(parents=True, exist_ok=True)
        buffer = StringIO()
        cfg.write(buffer)
        title = (row.get("IDTitle") or row.get("Title") or "").strip()
        header = f"# Game config for {game_id}"
        if title:
            header = f"{header} - {title}"
        content = f"{header}\n{buffer.getvalue()}"

        with primary_ini.open("w", encoding="utf-8", newline="\n") as outf:
            outf.write(content)

        if legacy_ini.exists():
            with legacy_ini.open("w", encoding="utf-8", newline="\n") as outf:
                outf.write(content)
        return True

    applied = 0
    for row in rows:
        game_id = (row.get("GameID") or "").strip().upper()
        if not game_id:
            continue
        applied_once = False
        for pdir in ppsspp_dirs:
            if apply_row(row, pdir):
                applied_once = True
        if applied_once:
            applied += 1

    fallback_applied = 0
    for pdir in ppsspp_dirs:
        system_dir = pdir / ".config" / "ppsspp" / "PSP" / "SYSTEM"
        if not system_dir.is_dir():
            continue
        for ini_path in system_dir.glob("*_ppsspp.ini"):
            game_id = ini_path.stem.replace("_ppsspp", "").upper()
            if game_id in id_rows:
                continue
            try:
                first_line = ini_path.open("r", encoding="utf-8-sig", errors="ignore").readline().strip()
            except OSError:
                continue
            match = HEADER_RE.match(first_line)
            if not match:
                continue
            title = match.group(2).strip()
            row = best_game_row(game_rows, title)
            if not row:
                continue
            row = dict(row)
            row["GameID"] = game_id
            row["IDTitle"] = title
            if apply_row(row, pdir):
                fallback_applied += 1

    print(
        f"Applied settings to {applied} game IDs across {len(ppsspp_dirs)} PPSSPP versions."
    )
    if fallback_applied:
        print(f"Applied by title match for {fallback_applied} existing game configs.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
