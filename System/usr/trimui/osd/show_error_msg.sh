#!/bin/sh

#assume no jq binary in system

msg=$1
VOL_MSG_JSON="\n\
{ \n\
    \"type\":\"error\", \n\
    \"id\":\"com.trimui.osd.msg.errorglobal\", \n\
    \"duration\":2000, \n\
    \"size\":2, \n\
    \"x\":340, \n\
    \"y\":350, \n\
    \"w\":300, \n\
    \"h\":80, \n\
    \"message\":\"  $msg\", \n\
    \"font\":\"\", \n\
    \"bg\":\"\", \n\
    \"icon\":\"\", \n\
    \"fontsize\":24, \n\
    \"fontcolor\":\"FFFFFFFF\" \n\
} \n"

echo -e $VOL_MSG_JSON > /tmp/trimui_osd/osd_toast_ms2
#echo -e $VOL_MSG_JSON > dump.txt