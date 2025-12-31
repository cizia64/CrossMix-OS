import csv
import io
import os
import re
import urllib.request
import zipfile
import xml.etree.ElementTree as ET

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
COMPAT_XLSX = os.path.join(
    ROOT_DIR,
    "TRIMUI Smart Pro - PSP Compatibility List (CrossMix-OS).xlsx",
)
COMPAT_REMOTE_URL = (
    "https://docs.google.com/spreadsheets/d/"
    "1fYv-rpOha_mvVn6-urlHKZh6sDM61J0YdCViFve0xH0/export?format=xlsx"
)
COMPAT_CSV = os.path.join(
    ROOT_DIR,
    "TRIMUI Smart Pro - PSP Compatibility List (CrossMix-OS) - Compatibility List.csv",
)
GAME_ID_CSV_CANDIDATES = [
    os.path.join(ROOT_DIR, "psp_game_ids.csv"),
    os.path.join(ROOT_DIR, "psp_game_ids_apollo.csv"),
]
OUT_SETTINGS = os.path.join(ROOT_DIR, "ppsspp_game_settings.csv")

ID_REGEX = re.compile(r"([A-Z]{4})[-_ ]?(\d{5})", re.I)

XLSX_NS = {"main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}

SETTINGS_KEYS = [
    "InternalResolution",
    "GraphicsBackend",
    "SkipBufferEffects",
    "AnisotropyLevel",
    "TextureBackoffCache",
    "SplineBezierQuality",
    "SkipGPUReadbacks",
    "CPUSpeed",
    "FrameSkip",
    "AutoFrameSkip",
    "TexScalingType",
    "TexScalingLevel",
]

STOPWORDS = {
    "a",
    "an",
    "and",
    "at",
    "by",
    "for",
    "from",
    "in",
    "of",
    "on",
    "or",
    "the",
    "to",
    "vs",
    "vs.",
}

MATCH_PRIORITY = {"exact": 3, "variant": 2, "superset": 1, "partial": 0}

NO_FUZZY_ID_TITLES = {
    "final fantasy",
}

ROMAN_NUMERALS = {
    "i": "1",
    "ii": "2",
    "iii": "3",
    "iv": "4",
    "v": "5",
    "vi": "6",
    "vii": "7",
    "viii": "8",
    "ix": "9",
    "x": "10",
    "xi": "11",
    "xii": "12",
    "xiii": "13",
    "xiv": "14",
    "xv": "15",
    "xvi": "16",
    "xvii": "17",
    "xviii": "18",
    "xix": "19",
    "xx": "20",
}


def normalize_title(title):
    title = title.lower()
    title = re.sub(r"\(.*?\)", " ", title)
    title = re.sub(r"\[.*?\]", " ", title)
    title = re.sub(r"[^a-z0-9]+", " ", title)
    title = re.sub(r"\s+", " ", title).strip()
    return title


def tokens_for_match(title):
    tokens = normalize_title(title).split()
    return [token for token in tokens if token not in STOPWORDS]


def numeric_tokens(tokens):
    numbers = set()
    for token in tokens:
        if token.isdigit():
            numbers.add(token)
            continue
        if token in ROMAN_NUMERALS:
            numbers.add(ROMAN_NUMERALS[token])
            continue
        match = re.match(r"^(\d+)", token)
        if match:
            numbers.add(match.group(1))
    return numbers


def parse_defaults(line):
    if not line:
        return {}
    defaults = {}
    line_l = line.lower()
    if "anisotropic" in line_l and "off" in line_l:
        defaults["AnisotropyLevel"] = "0"
    if "spline" in line_l and "low" in line_l:
        defaults["SplineBezierQuality"] = "0"
    if "lazy texture caching" in line_l:
        defaults["TextureBackoffCache"] = "True"
    match = re.search(r"(\d+)\s*mhz", line_l)
    if match:
        defaults["CPUSpeed"] = match.group(1)
    return defaults


def parse_notes(notes):
    settings = {}
    parsed = []
    notes_l = notes.lower()

    match = re.search(r"(\d+)\s*x\s*af", notes_l)
    if match:
        settings["AnisotropyLevel"] = match.group(1)
        parsed.append(f"AnisotropyLevel={match.group(1)}")

    match = re.search(r"(\d+)\s*x\s*xbrz", notes_l)
    if match:
        settings["TexScalingType"] = "0"
        settings["TexScalingLevel"] = match.group(1)
        parsed.append(f"TexScalingType=0,TexScalingLevel={match.group(1)}")

    if "skip gpu readbacks" in notes_l:
        settings["SkipGPUReadbacks"] = "True"
        parsed.append("SkipGPUReadbacks=True")

    if "lazy texture caching" in notes_l:
        settings["TextureBackoffCache"] = "True"
        parsed.append("TextureBackoffCache=True")

    if "spline" in notes_l or "bezier" in notes_l:
        if "low" in notes_l:
            settings["SplineBezierQuality"] = "0"
            parsed.append("SplineBezierQuality=0")
        elif "high" in notes_l:
            settings["SplineBezierQuality"] = "2"
            parsed.append("SplineBezierQuality=2")
        elif "medium" in notes_l:
            settings["SplineBezierQuality"] = "1"
            parsed.append("SplineBezierQuality=1")

    if "skip buffer effects" in notes_l:
        settings["SkipBufferEffects"] = "True"
        parsed.append("SkipBufferEffects=True")

    match = re.search(r"frameskip\s*=?\s*(\d+)", notes_l)
    if match:
        settings["FrameSkip"] = match.group(1)
        settings["AutoFrameSkip"] = "False"
        parsed.append(f"FrameSkip={match.group(1)}")

    match = re.search(r"(\d+)\s*mhz", notes_l)
    if match and ("clock" in notes_l or "cpu" in notes_l or "system" in notes_l):
        settings["CPUSpeed"] = match.group(1)
        parsed.append(f"CPUSpeed={match.group(1)}")

    return settings, ";".join(parsed)


def playability_settings(playability):
    if not playability:
        return {}, ""
    play_l = playability.lower()
    if "without frameskip" in play_l:
        return {"FrameSkip": "0", "AutoFrameSkip": "False"}, "Playability=NoFrameskip"
    if "frameskip of 1" in play_l:
        return {"FrameSkip": "1", "AutoFrameSkip": "False"}, "Playability=Frameskip1"
    if "somewhat playable" in play_l or "with frameskip" in play_l:
        return {"FrameSkip": "1", "AutoFrameSkip": "True"}, "Playability=Frameskip"
    if "unplayable" in play_l or "crashes" in play_l:
        return {"FrameSkip": "1", "AutoFrameSkip": "True"}, "Playability=Unplayable"
    return {}, ""


def read_shared_strings(zf):
    if "xl/sharedStrings.xml" not in zf.namelist():
        return []
    root = ET.fromstring(zf.read("xl/sharedStrings.xml"))
    strings = []
    for si in root.findall("main:si", XLSX_NS):
        parts = [t.text or "" for t in si.findall(".//main:t", XLSX_NS)]
        strings.append("".join(parts))
    return strings


def cell_value(cell, shared_strings):
    t = cell.get("t")
    if t == "inlineStr":
        is_node = cell.find("main:is", XLSX_NS)
        if is_node is None:
            return ""
        parts = [t_node.text or "" for t_node in is_node.findall(".//main:t", XLSX_NS)]
        return "".join(parts)
    v = cell.find("main:v", XLSX_NS)
    if v is None:
        return ""
    if t == "s":
        idx = int(v.text)
        return shared_strings[idx] if idx < len(shared_strings) else ""
    return v.text or ""


def col_from_ref(ref):
    match = re.match(r"([A-Z]+)", ref or "")
    return match.group(1) if match else ""


def load_style_fill_ids(zf):
    root = ET.fromstring(zf.read("xl/styles.xml"))
    cell_xfs = root.find("main:cellXfs", XLSX_NS)
    if cell_xfs is None:
        return []
    fill_ids = []
    for xf in cell_xfs.findall("main:xf", XLSX_NS):
        fill_ids.append(int(xf.get("fillId", "0")))
    return fill_ids


def parse_playability_legend(sheet_root, shared_strings, style_fill_ids):
    legend = {}
    rows = sheet_root.findall(".//main:sheetData/main:row", XLSX_NS)
    for row in rows:
        col_a = None
        col_b = None
        for cell in row.findall("main:c", XLSX_NS):
            col = col_from_ref(cell.get("r"))
            if col == "A":
                col_a = cell
            elif col == "B":
                col_b = cell
        if col_a is None or col_b is None:
            continue
        text = cell_value(col_b, shared_strings).strip()
        if not text:
            continue
        style_idx = col_a.get("s")
        if style_idx is None:
            continue
        sidx = int(style_idx)
        fill_id = style_fill_ids[sidx] if sidx < len(style_fill_ids) else None
        if fill_id is None:
            continue
        legend[fill_id] = text
    return legend


def find_header_row(sheet_root, shared_strings):
    rows = sheet_root.findall(".//main:sheetData/main:row", XLSX_NS)
    for idx, row in enumerate(rows):
        headers = {}
        for cell in row.findall("main:c", XLSX_NS):
            value = cell_value(cell, shared_strings).strip()
            if not value:
                continue
            headers[value] = col_from_ref(cell.get("r"))
        if "Game" in headers and "Resolution" in headers:
            return idx, headers
    return None, {}


def load_compat_entries_xlsx_zf(zf):
    shared_strings = read_shared_strings(zf)
    style_fill_ids = load_style_fill_ids(zf)
    sheet1 = ET.fromstring(zf.read("xl/worksheets/sheet1.xml"))
    sheet2 = ET.fromstring(zf.read("xl/worksheets/sheet2.xml"))

    default_line = ""
    for row in sheet1.findall(".//main:sheetData/main:row", XLSX_NS):
        if row.get("r") == "1":
            for cell in row.findall("main:c", XLSX_NS):
                if cell.get("r") == "A1":
                    default_line = cell_value(cell, shared_strings).strip()
                    break
            break
    defaults = parse_defaults(default_line)

    playability_legend = parse_playability_legend(sheet2, shared_strings, style_fill_ids)
    header_idx, headers = find_header_row(sheet1, shared_strings)
    if header_idx is None:
        raise SystemExit("Header row not found in compatibility list.")

    col_game = headers.get("Game")
    col_res = headers.get("Resolution")
    col_backend = headers.get("Backend")
    col_notes = headers.get("Notes")
    col_playability = headers.get("Playability")

    rows = sheet1.findall(".//main:sheetData/main:row", XLSX_NS)
    entries = []
    for row in rows[header_idx + 1 :]:
        values = {}
        styles = {}
        for cell in row.findall("main:c", XLSX_NS):
            col = col_from_ref(cell.get("r"))
            if col:
                values[col] = cell_value(cell, shared_strings).strip()
                styles[col] = cell.get("s")

        game = values.get(col_game or "", "").strip()
        if not game:
            continue

        playability = ""
        if col_playability and col_playability in styles and styles[col_playability] is not None:
            sidx = int(styles[col_playability])
            fill_id = style_fill_ids[sidx] if sidx < len(style_fill_ids) else None
            if fill_id is not None:
                playability = playability_legend.get(fill_id, "Unknown")

        entries.append(
            {
                "Game": game,
                "Normalized": normalize_title(game),
                "Tokens": tokens_for_match(game),
                "Resolution": values.get(col_res or "", "").strip(),
                "Backend": values.get(col_backend or "", "").strip(),
                "Notes": values.get(col_notes or "", "").strip(),
                "Playability": playability,
            }
        )

    return defaults, entries


def load_compat_entries_xlsx_path(xlsx_path):
    with zipfile.ZipFile(xlsx_path, "r") as zf:
        return load_compat_entries_xlsx_zf(zf)


def load_compat_entries_xlsx_bytes(xlsx_bytes):
    with zipfile.ZipFile(io.BytesIO(xlsx_bytes), "r") as zf:
        return load_compat_entries_xlsx_zf(zf)


def download_compat_xlsx(url, timeout=20):
    req = urllib.request.Request(url, headers={"User-Agent": "CrossMix-OS/ppsspp_setup"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        status = getattr(response, "status", None)
        if status is not None and status >= 400:
            raise RuntimeError(f"HTTP {status}")
        data = response.read()
    if not data.startswith(b"PK"):
        raise RuntimeError("Downloaded file does not look like a .xlsx archive.")
    return data


def load_compat_entries_csv():
    with open(COMPAT_CSV, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.read().splitlines()
    if len(lines) < 3:
        raise SystemExit("Compatibility list is too short.")
    default_line = lines[0].strip().strip("\"")
    defaults = parse_defaults(default_line)

    csv_lines = lines[2:]
    reader = csv.DictReader(csv_lines)
    entries = []
    for row in reader:
        game = (row.get("Game") or "").strip()
        if not game:
            continue
        entries.append(
            {
                "Game": game,
                "Normalized": normalize_title(game),
                "Tokens": tokens_for_match(game),
                "Resolution": (row.get("Resolution") or "").strip(),
                "Backend": (row.get("Backend") or "").strip(),
                "Notes": (row.get("Notes") or "").strip(),
                "Playability": "",
            }
        )
    return defaults, entries


def load_compat_entries():
    if COMPAT_REMOTE_URL:
        try:
            remote_bytes = download_compat_xlsx(COMPAT_REMOTE_URL)
            result = load_compat_entries_xlsx_bytes(remote_bytes)
            print(f"Compatibility list source: remote ({COMPAT_REMOTE_URL})")
            return result
        except (Exception, SystemExit) as exc:
            print(f"Remote compatibility list unavailable ({exc}); using local files instead.")
    if os.path.isfile(COMPAT_XLSX):
        result = load_compat_entries_xlsx_path(COMPAT_XLSX)
        print(f"Compatibility list source: local xlsx ({COMPAT_XLSX})")
        return result
    if os.path.isfile(COMPAT_CSV):
        result = load_compat_entries_csv()
        print(f"Compatibility list source: local csv ({COMPAT_CSV})")
        return result
    raise SystemExit("Missing compatibility list (.xlsx or .csv).")


def load_game_ids():
    csv_path = None
    for candidate in GAME_ID_CSV_CANDIDATES:
        if os.path.isfile(candidate):
            csv_path = candidate
            break
    if not csv_path:
        raise SystemExit("Missing game ID list (psp_game_ids.csv).")

    entries = []
    with open(csv_path, "r", encoding="utf-8", errors="ignore") as f:
        reader = csv.DictReader(f)
        for row in reader:
            title_id = (row.get("title_id") or "").strip()
            title = (row.get("title") or "").strip()
            if not title_id or not title:
                continue
            match = ID_REGEX.search(title_id)
            if not match:
                continue
            game_id = (match.group(1) + match.group(2)).upper()
            entries.append(
                {
                    "GameID": game_id,
                    "Title": title,
                    "Normalized": normalize_title(title),
                    "Tokens": tokens_for_match(title),
                    "Region": (row.get("region") or "").strip(),
                    "Category": (row.get("category") or "").strip(),
                }
            )
    return entries


def score_match(entry, id_entry):
    entry_norm = entry["Normalized"]
    id_norm = id_entry["Normalized"]
    if not entry_norm or not id_norm:
        return 0.0, ""
    if entry_norm == id_norm:
        return 2.0, "exact"
    if id_norm in NO_FUZZY_ID_TITLES:
        return 0.0, ""

    entry_tokens = entry["Tokens"]
    id_tokens = id_entry["Tokens"]
    if len(entry_tokens) < 2 or len(id_tokens) < 2:
        return 0.0, ""

    entry_nums = numeric_tokens(entry_tokens)
    id_nums = numeric_tokens(id_tokens)
    if entry_nums or id_nums:
        if entry_nums.isdisjoint(id_nums):
            return 0.0, ""

    common = set(entry_tokens) & set(id_tokens)
    min_common = 2 if len(entry_tokens) >= 2 and len(id_tokens) >= 2 else 1
    if len(common) < min_common:
        return 0.0, ""

    ratio_entry = len(common) / len(entry_tokens)
    ratio_id = len(common) / len(id_tokens)
    if max(ratio_entry, ratio_id) < 0.8:
        return 0.0, ""

    if min(len(entry_tokens), len(id_tokens)) <= 3:
        if ratio_entry < 1.0 and ratio_id < 1.0:
            return 0.0, ""

    if ratio_entry == 1.0 and ratio_id < 1.0:
        match_type = "variant"
    elif ratio_id == 1.0 and ratio_entry < 1.0:
        match_type = "superset"
    else:
        match_type = "partial"
    score = (ratio_entry + ratio_id) / 2.0
    return score, match_type


def best_match_for_id(id_entry, entries):
    best = None
    for entry in entries:
        score, match_type = score_match(entry, id_entry)
        if score <= 0:
            continue
        key = (score, MATCH_PRIORITY.get(match_type, 0), len(entry["Tokens"]))
        if best is None or key > best[0]:
            best = (key, entry, match_type, score)
    if best is None:
        return None
    _, entry, match_type, score = best
    return entry, match_type, score


def main():
    defaults, entries = load_compat_entries()
    id_entries = load_game_ids()

    settings_rows = {}
    unmatched = 0
    for id_entry in id_entries:
        matched = best_match_for_id(id_entry, entries)
        if not matched:
            unmatched += 1
            continue

        entry, match_type, match_score = matched

        settings = dict(defaults)
        res = entry["Resolution"].lower()
        if res.endswith("x") and res[:-1].isdigit():
            settings["InternalResolution"] = res[:-1]
        elif res.upper() == "SBE":
            settings["SkipBufferEffects"] = "True"

        backend = entry["Backend"].lower()
        if backend == "opengl":
            settings["GraphicsBackend"] = "0"
        elif backend == "vulkan":
            settings["GraphicsBackend"] = "3"

        note_settings, parsed_notes = parse_notes(entry["Notes"])
        settings.update(note_settings)

        play_settings, play_tag = playability_settings(entry.get("Playability", ""))
        for key, value in play_settings.items():
            settings.setdefault(key, value)
        if play_tag:
            parsed_notes = f"{parsed_notes};{play_tag}" if parsed_notes else play_tag

        settings_ordered = [settings.get(k, "") for k in SETTINGS_KEYS]

        row = [
            id_entry["GameID"],
            id_entry["Title"],
            id_entry["Region"],
            id_entry["Category"],
            entry["Game"],
            match_type,
            f"{match_score:.3f}",
            entry["Resolution"],
            entry["Backend"],
            entry.get("Playability", ""),
            *settings_ordered,
            parsed_notes,
            entry["Notes"],
        ]
        existing = settings_rows.get(id_entry["GameID"])
        if existing is None or float(row[6]) > float(existing[6]):
            settings_rows[id_entry["GameID"]] = row

    with open(OUT_SETTINGS, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(
            [
                "GameID",
                "IDTitle",
                "IDRegion",
                "IDCategory",
                "Game",
                "MatchType",
                "MatchScore",
                "Resolution",
                "Backend",
                "Playability",
                *SETTINGS_KEYS,
                "NotesParsed",
                "NotesOriginal",
            ]
        )
        for game_id in sorted(settings_rows):
            writer.writerow(settings_rows[game_id])

    print(f"Wrote: {OUT_SETTINGS}")
    print(f"Matches: {len(settings_rows)} game IDs")
    print(f"Unmatched: {unmatched} game IDs")


if __name__ == "__main__":
    main()
