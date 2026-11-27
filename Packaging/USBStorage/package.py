#!/usr/bin/env python3
"""Cria um instalador pequeno para o CrossMix e verifica o binario ARM64."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import sys

root = Path(__file__).resolve().parents[2]
package = root / "Packaging/USBStorage"
resource = root / "System/resources/usb_storage"
out = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "USB-Storage-Fix-TrimUI.zip"
helper = (resource / "usb_exit_watchdog").read_bytes()
if len(helper) < 20 or helper[:5] != b"\x7fELF\x02" or int.from_bytes(helper[18:20], "little") != 183:
    raise SystemExit("Binario ausente ou incompatível: esperado ELF AArch64")

entries = {
    "LEIA-ME.txt": (package / "LEIA-ME.txt", False),
    "Apps/USBStorageFix/config.json": (package / "config.json", False),
    "Apps/USBStorageFix/launch.sh": (package / "launch.sh", True),
    "Apps/USBStorageFix/icon.png": (resource / "usb_icon.png", False),
    "Apps/USBStorageFix/payload/launch.sh": (resource / "launch.sh", True),
    "Apps/USBStorageFix/payload/usb_exit_watchdog": (resource / "usb_exit_watchdog", True),
}
out.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(out, "w") as z:
    for name, (path, executable) in entries.items():
        info = ZipInfo(name)
        info.create_system = 3
        info.external_attr = (0o100755 if executable else 0o100644) << 16
        z.writestr(info, path.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
with ZipFile(out) as z:
    bad = z.testzip()
    if bad:
        raise SystemExit("Arquivo corrompido: " + bad)
digest = hashlib.sha256(out.read_bytes()).hexdigest()
out.with_suffix(out.suffix + ".sha256").write_text(f"{digest}  {out.name}\n", encoding="ascii")
print(f"{out} | {len(entries)} arquivos | {out.stat().st_size} bytes | SHA-256 {digest}")
