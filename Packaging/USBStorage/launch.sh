#!/bin/sh
# Installer launched from the CrossMix Apps list or Commander.
set -eu
APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SD=/mnt/SDCARD
SOURCE="$APP_DIR/payload"
RESOURCES="$SD/System/resources/usb_storage"
RUNTIME=/usr/trimui/apps/usb_storage
LOG=/tmp/usb-storage-fix-install.log
exec >"$LOG" 2>&1

show_message() {
    if [ -x "$SD/System/usr/trimui/scripts/infoscreen.sh" ]; then
        "$SD/System/usr/trimui/scripts/infoscreen.sh" -m "$1" -t 4 || true
    fi
}
fail() { echo "$1"; show_message "$1"; exit 1; }

[ "$(id -u)" = 0 ] || fail "Instalacao precisa de permissao root."
grep -q ' /mnt/SDCARD ' /proc/mounts || fail "Cartao SD nao esta montado."
[ -d "$RESOURCES" ] && [ -d "$RUNTIME" ] || fail "USB Storage do CrossMix nao encontrado."
[ -f "$SOURCE/launch.sh" ] && [ -f "$SOURCE/usb_exit_watchdog" ] || fail "Pacote incompleto."

STAMP=$(date +%Y%m%d_%H%M%S)
BACKUP="$SD/Data/USBStorageFix/backup-$STAMP"
[ ! -e "$BACKUP" ] || fail "Backup com mesmo nome ja existe. Tente novamente."
mkdir -p "$BACKUP/resources" "$BACKUP/runtime"
for NAME in launch.sh usb_exit_watchdog; do
    [ ! -f "$RESOURCES/$NAME" ] || cp -p "$RESOURCES/$NAME" "$BACKUP/resources/$NAME"
    [ ! -f "$RUNTIME/$NAME" ] || cp -p "$RUNTIME/$NAME" "$BACKUP/runtime/$NAME"
done

rollback() {
    for NAME in launch.sh usb_exit_watchdog; do
        for DEST in "$RESOURCES" "$RUNTIME"; do
            case "$DEST" in "$RESOURCES") OLD="$BACKUP/resources/$NAME" ;; *) OLD="$BACKUP/runtime/$NAME" ;; esac
            if [ -f "$OLD" ]; then cp -p "$OLD" "$DEST/$NAME" || true; else rm -f "$DEST/$NAME"; fi
            rm -f "$DEST/$NAME.usbfix-tmp"
        done
    done
    sync
    echo "Falha na instalacao; arquivos anteriores restaurados quando possivel. Backup: $BACKUP"
    show_message "Falha ao instalar. Veja /tmp/usb-storage-fix-install.log"
}
trap rollback EXIT
trap 'exit 1' HUP INT TERM

for DEST in "$RESOURCES" "$RUNTIME"; do
    for NAME in launch.sh usb_exit_watchdog; do
        cp "$SOURCE/$NAME" "$DEST/$NAME.usbfix-tmp"
        cmp "$SOURCE/$NAME" "$DEST/$NAME.usbfix-tmp"
        chmod 755 "$DEST/$NAME.usbfix-tmp"
    done
done
for DEST in "$RESOURCES" "$RUNTIME"; do
    for NAME in launch.sh usb_exit_watchdog; do
        mv -f "$DEST/$NAME.usbfix-tmp" "$DEST/$NAME"
        cmp "$SOURCE/$NAME" "$DEST/$NAME"
    done
done
sync
trap - EXIT HUP INT TERM
echo "Instalado. Backup: $BACKUP"
show_message "USB Storage atualizado. Ejete o cartao no PC antes de pressionar B."
