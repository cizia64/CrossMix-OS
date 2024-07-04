#!/bin/sh
echo $0 $*
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir
progdir=$(pwd)

CrossMix_Style=$(/mnt/SDCARD/System/bin/jq -r '.["CROSSMIX STYLE"]' "/mnt/SDCARD/System/etc/crossmix.json")

if [ -d "$progdir/theme_$CrossMix_Style" ]; then
	cd "$progdir/theme_$CrossMix_Style"
else
	cd "$progdir"
fi

"$progdir/user_guide"
