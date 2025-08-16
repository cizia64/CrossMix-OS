#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

tabName="$1"
if [ $# -eq 0 ]; then
    tabName=$(jq -r '.["START TAB"]' /mnt/SDCARD/System/etc/crossmix.json)
else
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Setting $tabName as start tab."
fi

# Get the tab id or check if disabled/unknown
tabN=$(awk -v tabName="$tabName" '
BEGIN {tabName=tolower(tabName)}
$0 ~ /tab/ && !($0 ~ /focuson/) {
    count++;
    if ( $0 ~ tabName) {
        if ($2 ~ 0 ) {
            print 0
        } else {
            print count
        }
        exit
    }
}
' /mnt/UDISK/system.json)
if [ -z "$tabN" ] || [ "$tabN" -lt 1 ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Start tab is disabled."
    exit 1
fi

tabN=$((tabN - 1))
tab0=0

[ "$tabN" -gt 2 ] && tab0=$((tabN - 2))

jq ".[].[1].tabidx = $tabN | .[].[1].tabstartidx = $tab0" /mnt/SDCARD/System/resources/default_state.json >/tmp/tmp.json
mv /tmp/tmp.json /mnt/SDCARD/System/resources/default_state.json

# update crossmix.json configuration file
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
    echo "{}" >"$json_file"
fi

jq --arg tabName "$tabName" '. += {"START TAB": $tabName}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"
