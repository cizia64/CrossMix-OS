for i in /mnt/SDCARD/Themes/**/config.json.bck; do
  mv "$i" "$(dirname "$i")/$(basename "$i" .bck)"
done

/mnt/SDCARD/System/usr/trimui/scripts/mainui_state_update.sh "TITLES FONTSIZE" "default"
