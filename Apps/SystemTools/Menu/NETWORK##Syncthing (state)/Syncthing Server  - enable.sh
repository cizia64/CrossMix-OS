#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

### DO NOT CHANGE THESE, USE THE OPTIONS FILE!
SYNCUSER=trimui
SYNCPASS=trimuisync
DEVICENAME=Trimui\ Smart\ Pro

CONFIGPATH=/mnt/SDCARD/System/etc/syncthing
DEFAULTFOLDER=/mnt/SDCARD/syncthing
CONFIG_FILE="$CONFIGPATH/config.xml"
SYNCTHING=/mnt/SDCARD/System/bin/syncthing
XMLSTARLET="/mnt/SDCARD/System/bin/xml"
### DO NOT CHANGE THESE, USE THE OPTIONS FILE!

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Applying \"$(basename "$0" .sh)\" by default..."

json_file="/mnt/SDCARD/System/etc/crossmix.json"

if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi

/mnt/SDCARD/System/bin/jq '. += {"Syncthing": 1}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

pkill $SYNCTHING
if ! [ -f $CONFIG_FILE ]; then
  mkdir -p "$CONFIGPATH/data"
  $SYNCTHING generate --no-default-folder --gui-user="$SYNCUSER" --gui-password="$SYNCPASS" --config="$CONFIGPATH"
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
$SYNCTHING serve --no-restart --no-upgrade --config="$CONFIGPATH" --data="$CONFIGPATH/data" &

# we modify the DB entries to reflect the current state
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "Syncthing" "enabled"

sleep 1

IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}')
echo "Syncthing: http://$IP:8384"
/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Syncthing: http://$IP:8384" -t 4
