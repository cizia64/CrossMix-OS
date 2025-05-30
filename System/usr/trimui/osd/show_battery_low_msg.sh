#!/bin/sh

#assume no jq binary in system

BAT=$1
VOL_MSG_JSON="\n\
{ \n\
    \"type\":\"batterylow\", \n\
    \"id\":\"com.trimui.osd.msg.batteryglobal\", \n\
    \"duration\":2000, \n\
    \"size\":0, \n\
    \"x\":490, \n\
    \"y\":30, \n\
    \"w\":300, \n\
    \"h\":80, \n\
    \"message\":\" $BAT%\", \n\
    \"font\":\"\", \n\
    \"bg\":\"\", \n\
    \"icon\":\"\", \n\
    \"fontsize\":24, \n\
    \"fontcolor\":\"FFFFFFFF\" \n\
} \n"

echo -e $VOL_MSG_JSON > /tmp/trimui_osd/osd_toast_ms2
#echo -e $VOL_MSG_JSON > dump.txt
