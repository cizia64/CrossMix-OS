#!/bin/sh
echo "click:"$1

if [ -f /tmp/trimui_osd/osdd_show_up ] ; then

	detached()
	{
		touch /tmp/hide_osdd
		/mnt/SDCARD/System/usr/trimui/scripts/cmd_to_run_killer.sh
	}

	detached &

fi
