#!/bin/sh

output_file="/tmp/cpumax.sh"

/mnt/SDCARD/System/bin/sdl2imgshow \
    -i "/mnt/SDCARD/trimui/res/crossmix-os/bg-info.png" \
    -f "/mnt/SDCARD/System/resources/DejaVuSans.ttf" \
    -s 40 \
    -c "220,220,220" \
    -t "Applying \"$(basename "$0" .sh)\"." &

CPU_led_Loop() {
    cat <<'EOF'
#!/bin/sh

while true; do

    echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
    echo "Set CPU governor to performance."
    for CPU in /sys/devices/system/cpu/cpu[0-3]; do
        # Set minimum frequency
        echo -n "2000000" > "$CPU"/cpufreq/scaling_min_freq
        echo "Set minimum CPU frequency to 2000000 for $CPU."

        echo -n "2000000" > "$CPU"/cpufreq/scaling_max_freq
        echo "Set maximum CPU frequency to 2000000 for $CPU."
    done
    sleep 3
done


EOF
}

CPU_led_Loop >"$output_file"

chmod a+x "$output_file"

pkill -f "cpumax.sh"
"$output_file" &

sleep 0.1
pkill -f sdl2imgshow
