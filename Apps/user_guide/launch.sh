#!/bin/sh
echo $0 $*
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir
progdir=$(pwd)

CrossMix_Theme=$(/mnt/SDCARD/System/bin/jq -r '.["CrossMix Theme"]' "/mnt/SDCARD/System/etc/crossmix.json")

if [ -d "$progdir/theme_$CrossMix_Theme" ]; then
	cd "$progdir/theme_$CrossMix_Theme"
else
	cd "$progdir"
fi

"$progdir/user_guide"
