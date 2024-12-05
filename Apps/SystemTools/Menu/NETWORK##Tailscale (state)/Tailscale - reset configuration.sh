#!/bin/sh
export PATH=/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:/usr/trimui/bin:$PATH
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/mnt/SDCARD/Apps/PortMaster/PortMaster:/usr/trimui/lib:$LD_LIBRARY_PATH"

TAILSCALED="/mnt/SDCARD/System/bin/tailscaled"
TAILSCALE="/mnt/SDCARD/System/bin/tailscaled"
STATE_DIRECTORY="/mnt/SDCARD/System/etc/tailscale"

button=$(infoscreen.sh -i bg-stop-exit.png -m "Reset current Tailscale configuration ? A to continue B to cancel." -k "A B" -fs 29)
if [ "$button" = "B" ]; then
  exit
fi
$TAILSCALE down
pkill -9 "$TAILSCALED"
pkill -9 "$TAILSCALE"
rm -rf "$STATE_DIRECTORY"

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Tailscale reset configuration done." -k "A" -i bg-exit.png -t 1
