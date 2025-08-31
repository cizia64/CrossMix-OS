#!/bin/sh
# RetroAchievement Sound Selector for CrossMix. By Cizia

if ! pgrep "TermSP" >/dev/null; then
    /mnt/SDCARD/Apps/Terminal/launch_TermSP.sh -s 24 -e "$0"  
fi


export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib:/usr/trimui/lib:/mnt/SDCARD/System/lib:$tkdir/lib
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:$PM_DIR:${PATH:+:$PATH}"
stty -echo -icanon time 0 min 0  # deactivates echo and standard interactive input


BASEDIR="$(dirname "$0")/.RAsounds"
cd "$BASEDIR" || exit 1

ls *.ogg 2>/dev/null > /tmp/sound_list.txt || {
    echo "No .ogg files found."
    exit 1
}

total=$(wc -l < /tmp/sound_list.txt)
[ "$total" -eq 0 ] && echo "No sounds available." && exit 1

index=1
player_pid=""
PAGE_SIZE=20

draw_list() {
    clear
    echo "---------------------------------------------------------------------------------"
    echo "    Select your RetroAchievement sound and press A               (B to exit)"
    echo "---------------------------------------------------------------------------------"
	echo 

    # Calculate scrolling window
    start=$((index - PAGE_SIZE / 2))
    [ "$start" -lt 1 ] && start=1
    end=$((start + PAGE_SIZE - 1))
    [ "$end" -gt "$total" ] && end=$total

    # Correct start if end exceeds
    start=$((end - PAGE_SIZE + 1))
    [ "$start" -lt 1 ] && start=1

    i=1
    while read -r line; do
        if [ "$i" -lt "$start" ] || [ "$i" -gt "$end" ]; then
            i=$((i + 1))
            continue
        fi

        if [ "$i" -eq "$index" ]; then
            echo "> $line"
        else
            echo "  $line"
        fi
        i=$((i + 1))
    done < /tmp/sound_list.txt

}

play_sound() {
    sel=$(sed -n "${index}p" /tmp/sound_list.txt)
    [ -n "$player_pid" ] && kill "$player_pid" 2>/dev/null
    # mpv --no-video --quiet --volume=100 "$sel" >/dev/null 2>&1 &
	/usr/trimui/bin/mplayer -ao alsa -format s16le -novideo -softvol -softvol-max 100 -volume 100 "$sel" >/dev/null 2>&1 &
    player_pid=$!
}

draw_list
play_sound

while true; do

    button=$(/mnt/SDCARD/System/usr/trimui/scripts/getkey.sh "UP DOWN A B" 2>/dev/null)

    case "$button" in
        "UP")
            index=$((index - 1))
            [ "$index" -lt 1 ] && index=$total
            draw_list
            play_sound
            ;;
        "DOWN")
            index=$((index + 1))
            [ "$index" -gt "$total" ] && index=1
            draw_list
            play_sound
            ;;
        "A")
            sel=$(sed -n "${index}p" /tmp/sound_list.txt)
            [ -n "$player_pid" ] && kill "$player_pid" 2>/dev/null
            echo -e "\n\nCopying $sel..."
			cp "./$sel" "/mnt/SDCARD/RetroArch/.retroarch/assets/sounds/unlock.ogg"
			sleep 0.5
			sync
			killall -9 "RetroAchievement Unlock Sound.sh"
            exit 0
            ;;
        "B")
            [ -n "$player_pid" ] && kill "$player_pid" 2>/dev/null
			killall -9 "RetroAchievement Unlock Sound.sh"
            exit 1
            ;;
    esac

    sleep 0.1
done
