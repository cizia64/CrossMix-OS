#!/bin/bash

silent=false
for arg in "$@"; do
    if [ "$arg" = "-s" ]; then
        silent=true
        break
    fi
done

RomsFolder="/mnt/SDCARD/Roms"
EmuFolder="/mnt/SDCARD/Emus"

json_file="/mnt/SDCARD/Emus/show.json"
NumRemoved=0
NumAdded=0

if [ "$silent" = false ]; then
/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "./background.jpg" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 100  \
  -c "220,0,0" \
  -t " " & 
fi

write_entry() {
    label="$1"
    show="$2"
    echo "{"
    echo -e "\t\"label\": \"$label\","
    echo -e "\t\"show\": $show"
    echo "},"
}
echo "[" > $json_file



# we check if some emulators must be hidden from /mnt/SDCARD/Emus 
for subfolder in $EmuFolder/*/; do

	if [ -f "$subfolder/config.json" ]; then
		# RomPath=$(grep '"rompath":*' $subfolder/config.json |sed 's|.*"rompath":"\([^"]*\)".*|\1|')
		RomPath=$(/mnt/SDCARD/System/bin/jq -r '.rompath' "$subfolder/config.json")
		RomFolderName=$(basename "$RomPath")
		
		# Label=$(grep '"label":*' $subfolder/config.json | sed 's|.*"label":"\([^"]*\)".*|\1|')
		Label=$(/mnt/SDCARD/System/bin/jq -r '.label' "$subfolder/config.json")
		echo "--$Label--"

		if ! find "$RomsFolder/$RomFolderName" '!' -name '*.db' '!' -name '.gitkeep' -mindepth 1 -maxdepth 1 |  read; then
			echo "Removing $Label emulator (no roms in $RomFolderName folder)."
			write_entry "$Label" 0 >> $json_file
			let NumRemoved++;
		else
			echo "Adding $Label emulator (no roms in $RomFolderName folder)."
			write_entry "$Label" 1 >> $json_file
			let NumAdded++;

		fi
	fi
	
done


sed -i '$ s/,$//' $json_file
echo "]" >> $json_file

echo -ne "\n=============================\n"
echo -ne "${NumRemoved} hidden emulator(s)\n${NumAdded} displayed emulator(s)\n"
echo -ne "=============================\n\n"

if [ "$silent" = false ]; then
sleep 0.5
pkill -f sdl2imgshow
sleep 1

/mnt/SDCARD/System/bin/sdl2imgshow \
  -i "./background-info.jpg" \
  -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
  -s 40  \
  -c "255,255,255" \
  -t "${NumAdded} displayed emulator(s).      ${NumRemoved} hidden emulator(s)." & 

sleep 4

pkill -f sdl2imgshow

fi