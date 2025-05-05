#!/bin/sh

#assume no jq binary in system

msg=$1
VOL_MSG_JSON="\n\
{ \n\
    \"type\":\"default\", \n\
    \"id\":\"com.trimui.osd.msg.defaultlong\", \n\
    \"duration\":1000, \n\
    \"size\":3, \n\
    \"x\":140, \n\
    \"y\":500, \n\
    \"w\":300, \n\
    \"h\":80, \n\
    \"message\":\"$msg\", \n\
    \"font\":\"\", \n\
    \"bg\":\"\", \n\
    \"icon\":\"\", \n\
    \"fontsize\":24, \n\
    \"fontcolor\":\"FFFFFFFF\" \n\
} \n"

echo -e $VOL_MSG_JSON > /tmp/trimui_osd/osd_toast_ms2
#echo -e $VOL_MSG_JSON > dump.txt
