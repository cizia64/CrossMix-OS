#!/bin/sh

#assume no jq binary in system

MSG=$1
VOL_MSG_JSON="\n\
{ \n\
    \"type\":\"chargeroff\", \n\
    \"id\":\"com.trimui.osd.msg.batteryglobal\", \n\
    \"duration\":1000, \n\
    \"size\":0, \n\
    \"x\":490, \n\
    \"y\":580, \n\
    \"w\":300, \n\
    \"h\":80, \n\
    \"message\":\" $MSG\", \n\
    \"font\":\"\", \n\
    \"bg\":\"\", \n\
    \"icon\":\"\", \n\
    \"fontsize\":24, \n\
    \"fontcolor\":\"FFFFFFFF\" \n\
} \n"

echo -e $VOL_MSG_JSON > /tmp/trimui_osd/osd_toast_ms2
#echo -e $VOL_MSG_JSON > dump.txt
