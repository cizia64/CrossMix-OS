#!/bin/sh

/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Cleaning dot files... Please wait."

cd /mnt/SDCARD/
rm -rf .Spotlight-V100 .apDisk .fseventsd .TemporaryItems .Trash .Trashes
rm /mnt/SDCARD/._*

# Define directories to clean
directories="/mnt/SDCARD/Apps /mnt/SDCARD/System"

# Remove specific files and directories within the specified directories
for dir in $directories; do
    find "$dir" -depth \( \
        -type f \( -name "._*" -o -name ".DS_Store" \) -not -path "**/._state_seen/*" -delete \
        -o -type d -name "__MACOSX" -exec rm -rf {} + \
    \)
done



button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Dot clean done. Press X to run a full clean on the SD card in background (very long). Press B to Quit" -fs 28 -k "X B MENU")
if [ "$button" = "X" ]; then
    (
        /mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "Cleaning dot files in background."

		
		# Define directories to clean
        directories="/mnt/SDCARD"

        # Remove specific files and directories within the specified directories
        for dir in $directories; do
            find "$dir" -depth \( \
                -type f \( -name "._*" -o -name ".DS_Store" -o -name "*_cache[0-9].db" \) -not -path "**/._state_seen/*" -delete \
                -o -type d -name "__MACOSX" -exec rm -rf {} + \
            \)
        done

        # Play sound after cleaning
        aplay "/mnt/SDCARD/trimui/res/sound/Dot Files Remover Finished.wav"
    ) &
fi
