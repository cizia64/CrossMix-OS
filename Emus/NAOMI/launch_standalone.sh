#!/bin/sh
echo $0 $*

EMU_DIR=/mnt/SDCARD/Emus/NAOMI
FLYCAST_DIR=/mnt/SDCARD/Emus/DC/flycast

$EMU_DIR/cpufreq.sh
$EMU_DIR/effect.sh

cd "$FLYCAST_DIR"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:lib
export FLYCAST_BIOS_DIR="/mnt/SDCARD/BIOS/dc/"
export FLYCAST_DATA_DIR=$FLYCAST_BIOS_DIR
export FLYCAST_CONFIG_DIR="$FLYCAST_DIR/config/"

FLYCAST_BINARY="./flycast"

if grep -i "dowork 0x" "/tmp/log/messages" | tail -n 1 | grep -iq "(KMFD Xtreme)"; then
    echo "Flycast Xtreme selected"
    FLYCAST_BINARY="${FLYCAST_BINARY}_xtreme"
fi

"$FLYCAST_BINARY" "$@" 