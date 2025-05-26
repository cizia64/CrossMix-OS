#!/bin/sh

SAVE_FILE="/tmp/cpufreq_saved.conf"

governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
min_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq)
max_freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)

active_cpus=0
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    if [ -f "$cpu/online" ]; then
        if [ "$(cat $cpu/online)" -eq 1 ]; then
            active_cpus=$((active_cpus + 1))
        fi
    else
        if echo "$cpu" | grep -q "cpu0"; then
            active_cpus=$((active_cpus + 1))
        fi
    fi
done

cat <<EOF > "$SAVE_FILE"
GOVERNOR=$governor
MIN_FREQ=$min_freq
MAX_FREQ=$max_freq
ACTIVE_CPUS=$active_cpus
EOF

echo "CPU settings saved to $SAVE_FILE:"
cat "$SAVE_FILE"
