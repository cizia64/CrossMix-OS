"""
Create a clean PSP Title-ID CSV from PPSSPP's redump.csv.

Input:  psp_redump.csv (downloaded from PPSSPP)
Output: psp_game_ids.csv with columns: title_id,title,region,category
"""

from __future__ import annotations

import csv
from pathlib import Path


def normalize_title_id(raw_serial: str) -> str:
    # redump.csv sometimes uses spaces in some entries, e.g. "ULJM 05964"
    normalized = raw_serial.strip().replace(" ", "-")
    return normalized


def main() -> None:
    root_dir = Path(__file__).resolve().parent
    input_candidates = [root_dir / "psp_redump.csv", root_dir / "psp_games_dump.csv"]
    input_csv_path = next((path for path in input_candidates if path.exists()), None)
    output_csv_path = root_dir / "psp_game_ids.csv"

    if input_csv_path is None:
        raise FileNotFoundError(
            "Missing redump CSV. Expected psp_redump.csv (or legacy psp_games_dump.csv)."
        )

    seen: set[tuple[str, str]] = set()  # (title_id, title)

    with input_csv_path.open("r", encoding="utf-8", newline="") as f_in, output_csv_path.open(
        "w", encoding="utf-8", newline=""
    ) as f_out:
        reader = csv.DictReader(f_in)
        writer = csv.writer(f_out, lineterminator="\n")
        writer.writerow(["title_id", "title", "region", "category"])

        for row in reader:
            if (row.get("System") or "").strip() != "Sony PlayStation Portable":
                continue

            title = (row.get("Title") or "").strip()
            region = (row.get("Region") or "").strip()
            category = (row.get("Category") or "").strip()
            serial_field = (row.get("Serial") or "").strip()

            if not title or not serial_field:
                continue

            # Some rows have multiple serials, e.g. "ULJM 05964, ULJM 06212"
            serial_candidates = [s.strip() for s in serial_field.split(",") if s.strip()]
            for serial in serial_candidates:
                title_id = normalize_title_id(serial)
                key = (title_id, title)
                if key in seen:
                    continue
                seen.add(key)
                writer.writerow([title_id, title, region, category])

    print(f"Wrote {len(seen)} rows to {output_csv_path}")


if __name__ == "__main__":
    main()
