#!/bin/sh
echo "launch info widget"
CUR_DIR=$(dirname "$0")
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$progdir

cd $CUR_DIR/

mkdir -p /tmp/crossmix_cpu_info
./pic2argb ./default.png /tmp/crossmix_cpu_info/vfb_osd

# echo -e "{ \"duration\":2000, \"x\":920, \"y\":330, \"message\":\"launch \", \"font\":\"\", \"icon\":\"\", \"fontsize\":24 }" > /tmp/trimui_osd/osd_toast_msg
