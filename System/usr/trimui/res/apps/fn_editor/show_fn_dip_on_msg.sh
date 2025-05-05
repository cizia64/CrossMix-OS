#!/bin/sh
PATH="/mnt/SDCARD/System/bin:$PATH"
SCENE_DIR="/usr/trimui/scene"
SCRIPT_JSON="/usr/trimui/apps/fn_editor/scripts.json"

# Find current script name (only if one fn action is enabled)
files=$(find "$SCENE_DIR" -type f)

if [ -z "$files" ]; then
    Current_FnScript="No Fn action set"
elif [ $(echo "$files" | wc -l) -eq 1 ]; then
    filename=$(basename "$files")
    Current_FnScript="$(jq -r --arg launch "$filename" '.[] | select(.launch == $launch) | .name' "$SCRIPT_JSON") ON"
else
    Current_FnScript="Multiple Fn actions ON"
fi


# Set toaster size based on Current_FnScript length
Current_FnScript_txtsize=${#Current_FnScript}

if [ "$Current_FnScript_txtsize" -lt 11 ]; then
    message_size="0"
elif [ "$Current_FnScript_txtsize" -lt 17 ]; then
    message_size="1"
elif [ "$Current_FnScript_txtsize" -lt 30 ]; then
    message_size="2"
else
    message_size="3"
fi

# for debugging
# echo "Current_FnScript_txtsize: $Current_FnScript_txtsize"
# echo "message_size: $message_size"


msg="$Current_FnScript"

jq -n \
  --arg msg "$msg" \
  --argjson message_size "$message_size" \
  '{
    type: "default",
    id: "com.trimui.osd.msg.fneditor_dip",
    duration: 1000,
    size: $message_size,
    x: 10,
    y: 580,
    w: 300,
    h: 80,
    message: (" " + $msg),
    font: "",
    bg: "",
    icon: "/usr/trimui/apps/fn_editor/ic-fn-on-tips.png",
    fontsize: 24,
    fontcolor: "FF36FFA0"
  }' > /tmp/trimui_osd/osd_toast_msg
