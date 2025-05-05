#!/bin/sh

#assume no jq binary in system

VOLUME=$1
VOL_MSG_JSON="\n\
{ \n\
    \"type\":\"volume\", \n\
    \"id\":\"com.trimui.osd.msg.volumeglobal\", \n\
    \"duration\":1000, \n\
    \"size\":0, \n\
    \"x\":850, \n\
    \"y\":30, \n\
    \"w\":300, \n\
    \"h\":80, \n\
    \"message\":\"$VOLUME / 20\", \n\
    \"font\":\"\", \n\
    \"bg\":\"\", \n\
    \"icon\":\"\", \n\
    \"fontsize\":24, \n\
    \"fontcolor\":\"FFFFFFFF\" \n\
} \n"

echo -e $VOL_MSG_JSON > /tmp/trimui_osd/osd_toast_ms2
#echo -e $VOL_MSG_JSON > dump.txt
