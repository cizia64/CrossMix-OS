#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "Applying \"$(basename "$0" .sh)\" by default..." &

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"TELNET": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill telnetd
telnetd

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'TELNET (enabled)',pinyin = 'TELNET (enabled)',cpinyin = 'TELNET (enabled)',opinyin = 'TELNET (enabled)' WHERE disp = 'TELNET (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'TELNET (enabled)' WHERE ppath = 'TELNET (disabled)';"
sync
json_file="/tmp/state.json"

# we modify the current menu position as the DB entry has changed
jq '.list |= map(if .ppath == "TELNET (disabled)" then .ppath = "TELNET (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

pkill -f sdl2imgshow
sleep 1
IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "TELNET server IP: $IP"
/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "TELNET server IP: $IP" &

sleep 4

pkill -f sdl2imgshow
