#!/bin/sh

source /mnt/SDCARD/System/etc/ex_config

mkdir -p ~/.config/

if [[ "$NETWORK_FIX" == "Y" ]]; then

    if [ ! -f "$EX_CONFIG_PATH/mac_addr.conf" ]; then
        # Generate random bytes
        bytes=$(dd if=/dev/urandom bs=6 count=1 2>/dev/null | xxd -p)

        # Format bytes into MAC address format
        MAC_ADDR=$(echo "00:00:${bytes:4:2}:${bytes:6:2}:${bytes:8:2}:${bytes:10:2}")

        # Output the random MAC address
        echo "MAC_ADDR=$MAC_ADDR" >> "$EX_CONFIG_PATH/mac_addr.conf"
    else
        source "$EX_CONFIG_PATH/mac_addr.conf"
    fi

    ## MAC ADDRESS STUFF FROM: https://github.com/tGecko/TrimUI-Smart-Pro-resources?tab=readme-ov-file#startup-script

    ## Force a decent macaddr
    ifconfig wlan0 down
    ifconfig wlan0 hw ether "$MAC_ADDR"
    ifconfig wlan0 up
fi

/mnt/SDCARD/System/bin/ex_update.sh

if [[ "$NETWORK_SSH" == "Y" ]]; then
    mkdir -p /etc/dropbear

    # Currently broken
    nice -2 dropbear -R
fi

if [[ "$NETWORK_SFTPGO" == "Y" ]]; then
    mkdir -p /opt/sftpgo

    nice -2 /mnt/SDCARD/System/sftpgo/sftpgo serve -c /mnt/SDCARD/System/sftpgo/ > /dev/null &
fi
