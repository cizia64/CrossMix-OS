#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 50 \
  -c "220,220,220" \
  -t "$(basename "$0" .sh) by default." &

cat >/mnt/SDCARD/System/starts/start_tab.sh <<-EOM
cat > /tmp/state.json <<- EOM2
{
	"list":	[{
			"title":	0,
			"type":	0,
			"tabidx":	4,
			"tabstartidx":	3
		}]
}
EOM2
EOM

chmod a+x /mnt/SDCARD/System/starts/start_tab.sh

# Menu modification to reflect the change immediately

script_name=$(basename "$0" .sh)

json_file="/mnt/SDCARD/System/etc/crossmix.json"
if [ ! -f "$json_file" ]; then
  echo "{}" >"$json_file"
fi
/mnt/SDCARD/System/bin/jq --arg script_name "$script_name" '. += {"START TAB": $script_name}' "$json_file" >"/tmp/json_file.tmp" && mv "/tmp/json_file.tmp" "$json_file"

database_file="/mnt/SDCARD/Apps/SystemTools/Menu/Menu_cache7.db"

sqlite3 "$database_file" "UPDATE Menu_roms SET disp = 'START TAB ($script_name)',pinyin = 'START TAB ($script_name)',cpinyin = 'START TAB ($script_name)',opinyin = 'START TAB ($script_name)' WHERE disp LIKE 'START TAB (%)';"
sqlite3 "$database_file" "UPDATE Menu_roms SET ppath = 'START TAB ($script_name)' WHERE ppath LIKE 'START TAB (%)';"
json_file="/tmp/state.json"

jq --arg script_name "$script_name" '.list |= map(if (.ppath | index("START TAB ")) then .ppath = "START TAB (\($script_name))" else . end)' "$json_file" >"$json_file.tmp" && mv "$json_file.tmp" "$json_file"

sync
sleep 0.1
pkill -f sdl2imgshow
