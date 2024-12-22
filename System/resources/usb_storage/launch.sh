#!/bin/sh
echo $0 $*
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir
echo "=============================================="
echo "============== USB Storage Mode  ============="
echo "=============================================="

configure_usb_gadget() {

	GADGET_PATH="/sys/kernel/config/usb_gadget/g1"
	DEV_EMMC="/dev/by-name/UDISK"

	if [ ! -d "$GADGET_PATH" ]; then
		mkdir -p "$GADGET_PATH"
	fi

	MASS_STORAGE_PATH="$GADGET_PATH/functions/mass_storage.usb0"

	if [ ! -d "$MASS_STORAGE_PATH" ]; then
		mkdir -p "$MASS_STORAGE_PATH"
	fi

	echo "Configuring Lun for eMMC..."
	if [ ! -d "$MASS_STORAGE_PATH/Lun.1" ]; then
		mkdir -p "$MASS_STORAGE_PATH/Lun.1"
	fi
	echo $DEV_EMMC >"$MASS_STORAGE_PATH/Lun.1/file"
	sync
}

task_killer() {
	r=0
	for p in $1; do
		if [ -d "/proc/$p" ] && [ $p -ne $$ ]; then
			kill $2 $p
			r=1
		fi
	done
	return $r
}

kill_hooked_tasks() {
	c=0
	while [ $c -lt 5 ]; do
		pids=$(fuser -m $1)
		if task_killer "$pids" $2; then
			return
		fi
		sleep 0.05
		c=$((c + 1))
	done
}

if [ "$0" = "/tmp/usb_storage.sh" ]; then

	sync
	killall -9 S99runtrimui
	killall -9 runtrimui.sh
	pkill -9 -f cmd_to_run.sh
	pkill -9 -f launch.sh
	killall -9 trimui_scened
	killall -9 smbd MainUI keymon ntpd logd logread udevd netifd MtpDaemon wpa_supplicant avahi-daemon syslogd com.trimui.cpuperformance.sh udhcpc

	# terminate all apps which are using SD card
	kill_hooked_tasks /mnt/SDCARD
	sleep 0.1
	kill_hooked_tasks /mnt/SDCARD -9
	sync

	if ! pgrep "trimui_inputd" >/dev/null; then
		/usr/trimui/bin/trimui_inputd &
		sleep 0.5
	fi

	TYPE=$(blkid /dev/by-name/UDISK | awk -F 'TYPE="' '{print $2}' | cut -d '"' -f 1)
	if [ "$TYPE" = "vfat" ]; then
		configure_usb_gadget
	fi

	# un-mount
	umount /rom /overlay
	swapoff -a
	umount -r /mnt/SDCARD
	umount /mnt/SDCARD
	umount /mnt/UDISK

	############# DEBUG #############
	# fuser -m /mnt/SDCARD > /usr/trimui/usb_storage.log
	# lsof /mnt/SDCARD >> /usr/trimui/usb_storage.log
	# mount >> /usr/trimui/usb_storage.log
	#################################

	echo 1 >/tmp/stay_awake

	# put adb in mass storage mode
	/bin/setusbconfig mass_storage,adb

	# TrimUI waiting app
	cd /usr/trimui/apps/usb_storage/
	chmod 777 usb_storage
	./usb_storage
	sync

	# Reboot message
	/usr/trimui/bin/sdldisplay/sdldisplay ./rebooting.png &

	# disable adb
	/bin/setusbconfig none
	sleep 1
	pkill -2 adbd
	pkill -9 sdldisplay
	sleep 0.3
	pkill -9 adbd

	sync

	rm /tmp/stay_awake
	sleep 2
	/sbin/reboot

fi

if [ ! -f /tmp/usb_storage.sh ]; then
	cp -f "$0" /tmp/usb_storage.sh
fi

# run the script totally detached from current shell
pgrep -f /tmp/usb_storage.sh || (
	manualPath="/usr/trimui/apps/usb_storage/manual"
	if [ -f "${manualPath}.png" ]; then
		button=$(/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -i "${manualPath}.png" -k "A B")
		if [ "$button" = "B" ]; then
			/mnt/SDCARD/System/usr/trimui/scripts/infoscreen.sh -m "USB Storage launch canceled."
			pkill -9 launch.sh
			exit 1
		fi
		mv ${manualPath}.png ${manualPath}_done.png
	fi
	cp /mnt/SDCARD/System/bin/sdl2imgshow /tmp
	chmod a+x /tmp/sdl2imgshow
	set -m
	su root -c "/usr/bin/nohup /tmp/usb_storage.sh $1 </dev/null >/dev/null 2>&1 &"
)
while true; do
	sleep 10
done
