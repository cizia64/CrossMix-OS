#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

### DO NOT CHANGE THESE, USE THE OPTIONS FILE!
SYNCUSER=trimui
SYNCPASS=trimuisync
DEVICENAME=Trimui\ Smart\ Pro

CONFIGPATH=/mnt/SDCARD/System/etc/syncthing
DEFAULTFOLDER=/mnt/SDCARD/syncthing
CONFIG_FILE="/mnt/SDCARD/System/etc/syncthing/config.xml"
XMLSTARLET="/mnt/SDCARD/System/bin/xml"
### DO NOT CHANGE THESE, USE THE OPTIONS FILE!

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"Syncthing": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill /mnt/SDCARD/System/bin/syncthing
if ! [ -f /mnt/SDCARD/System/bin/syncthing/config.xml ]; then
  mkdir -p "$CONFIGPATH/data"
  /mnt/SDCARD/System/bin/syncthing generate --no-default-folder --gui-user="$SYNCUSER" --gui-password="$SYNCPASS" --config="$CONFIGPATH"
  sync
  sleep 2

  # allow for external connections and show a better device name
  # Modify urAccepted to -1
  $XMLSTARLET ed --inplace -u "//options/urAccepted" -v "-1" "$CONFIG_FILE"
  # Replace the GUI address with 0.0.0.0:8384
  $XMLSTARLET ed --inplace -u "//gui/address" -v "0.0.0.0:8384" "$CONFIG_FILE"
  # Replace TinaLinux with $DEVICENAME
  $XMLSTARLET ed --inplace -u "//device/@name" -v "$DEVICENAME" "$CONFIG_FILE"
  # Replace path="~" with path="$DEFAULTFOLDER"
  $XMLSTARLET ed --inplace -u "//folder/@path" -v "$DEFAULTFOLDER" "$CONFIG_FILE"

  sync

  mkdir -p $DEFAULTFOLDER
fi
sleep 0.5
sync
/mnt/SDCARD/System/bin/syncthing serve --no-restart --no-upgrade --config="$CONFIGPATH" --data="$CONFIGPATH/data" &

# we modify the DB entries to reflect the current state

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'Syncthing (enabled)',pinyin = 'Syncthing (enabled)',cpinyin = 'Syncthing (enabled)',opinyin = 'Syncthing (enabled)' WHERE disp = 'Syncthing (disabled)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'Syncthing (enabled)' WHERE ppath = 'Syncthing (disabled)';"
sync

# we modify the current menu position as the DB entry has changed
json_file="/tmp/state.json"
jq '.list |= map(if .ppath == "Syncthing (disabled)" then .ppath = "Syncthing (enabled)" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sleep 1

IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "Syncthing: http://$IP:8384"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Syncthing: http://$IP:8384" -t 4
