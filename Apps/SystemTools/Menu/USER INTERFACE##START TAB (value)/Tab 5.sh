#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

silent=false
for arg in "$@"; do
  if [ "$arg" = "-s" ]; then
    silent=true
    break
  fi
done

if [ "$silent" = false ]; then
  /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "$(basename "$0" .sh) by default."
fi

cat >/mnt/SDCARD/System/starts/start_tab.sh <<-EOM
cat > /tmp/state.json <<- EOM2
{
	"list":	[{
		}, {
			"title":	0,
			"type":	0,
			"tabidx":	4,
			"tabstartidx":	3,
			"tabstate":	[{}]
		}]
}
EOM2
EOM

chmod a+x /mnt/SDCARD/System/starts/start_tab.sh

# Menu modification to reflect the change immediately

# update crossmix.json configuration file
script_name=$(basename "$0" .sh)
json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
jq --arg script_name "$script_name" '. += {"START TAB": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

# update database of "System Tools" database
/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "START TAB" "$script_name"