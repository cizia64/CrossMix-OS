#!/bin/sh

fn_script=com.trimui.led_on.sh
fn_editor_fd=/usr/trimui/apps/fn_editor
fn_editor_scripts="$fn_editor_fd/scripts.json"
fn_editor_tmp=/tmp/fn_editor.json

# we need `jq`
PATH="/mnt/SDCARD/System/bin:$PATH"

if (grep -q $fn_script $fn_editor_scripts 2>/dev/null); then
    echo "$fn_script is already installed; nothing to do."
else
    cfg_js=`cat ./config.json`

    cp $fn_script "$fn_editor_fd/"
    echo `cat $fn_editor_scripts` | jq ".[.[]|length+1] += $cfg_js" > $fn_editor_tmp 
    mv -f $fn_editor_tmp $fn_editor_scripts
fi