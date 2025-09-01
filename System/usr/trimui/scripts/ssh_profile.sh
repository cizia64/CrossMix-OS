#!/bin/sh

echo
echo "Do you want to enable the CrossMix dev profile? [Y/n] "
stty -echo -icanon
answer=$(dd bs=1 count=1 2>/dev/null)
stty echo icanon
answer="${answer:-Y}"

if [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
    clear
    cat <<'EOF'

     ██████╗██████╗  ██████╗ ███████╗███████╗███╗   ███╗██╗██╗  ██╗
    ██╔════╝██╔══██╗██╔═══██╗██╔════╝██╔════╝████╗ ████║██║╚██╗██╔╝
    ██║     ██████╔╝██║   ██║███████╗███████╗██╔████╔██║██║ ╚███╔╝ 
    ██║     ██╔══██╗██║   ██║╚════██║╚════██║██║╚██╔╝██║██║ ██╔██╗ 
    ╚██████╗██║  ██║╚██████╔╝███████║███████║██║ ╚═╝ ██║██║██╔╝ ██╗
     ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝
 
┌──────────────────────────────────────────────────────────────────────────┐
│  The CrossMix dev profile for SSH grants easier access to all binaries   │
│  and libraries configured in CrossMix. However, this is not the standard │
│  Trimui environment: some scripts may require additional setup to run    │
│  properly when launched from the console interface.                      │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘ 
EOF
    # Set PATH for dev profile
    export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:/mnt/SDCARD/System/bin/imagemagick/bin:$PATH"

    # Set LD_LIBRARY_PATH for dev profile
    export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:/usr/lib:/mnt/SDCARD/System/bin/imagemagick/lib64/:${LD_LIBRARY_PATH:-}"
    # for ImageMagick:
    export MAGICK_CODER_MODULE_PATH=/mnt/SDCARD/System/bin/imagemagick/lib64/ImageMagick-6.9.10/config-Q16/coders
    export MAGICK_CONFIGURE_PATH=/mnt/SDCARD/System/bin/imagemagick/bin
    # for mbrola voices:
    export XDG_DATA_DIRS=/mnt/SDCARD/System/etc/espeak-ng-data:$XDG_DATA_DIRS

    # set default path
    cd /tmp

else
    echo "CrossMix dev profile not enabled."
fi
