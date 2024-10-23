for i in /mnt/SDCARD/Themes/**/config.json; do
    if [ ! -f "$i".bck ]; then
      cp "$i" "$i".bck
    fi
    sed -i 's/"content_font1":[0-9]*/"content_font1":16/' "$i"
done

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "TITLES FONTSIZE" "16"
