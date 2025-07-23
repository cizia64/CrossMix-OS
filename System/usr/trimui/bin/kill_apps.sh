#!/bin/sh

SELF_PID=$$

# Checks if there is another instance of kill_apps.sh running
if pgrep -f "kill_apps.sh" | grep -v "^$SELF_PID$" > /dev/null; then
    echo "Une autre instance de kill_apps.sh est déjà en cours." >&2
    exit 1
fi

# Configuration
SCRIPTS_DIR="/mnt/SDCARD/System/usr/trimui/scripts"
SYSTEM_DIR="/mnt/SDCARD/System"
TRIMUI_DIR="/mnt/SDCARD/trimui"

# Logging function
log_message() {
    echo "$(date '+%H:%M:%S') [kill_apps]: $1"
}

# Hardware feedback functions
vibrate_short() {
    echo -n 1 >/sys/class/gpio/gpio227/value
    sleep 0.1
    echo -n 0 >/sys/class/gpio/gpio227/value
}

set_led_animation() {
    local color=$1
    local cycles=$2
    local duration=$3
    local effect=${4:-5}
    
    
    if [ ! -w "/sys/class/led_anim/effect_enable" ]; then
        log_message "Warning: Cannot access LED animation"
        chmod a+w /sys/class/led_anim/*
    fi
    
    echo 1 >/sys/class/led_anim/effect_enable
    echo "$color" >/sys/class/led_anim/effect_rgb_hex_lr 2>/dev/null
    echo "$cycles" >/sys/class/led_anim/effect_cycles_lr 2>/dev/null
    echo "$duration" >/sys/class/led_anim/effect_duration_lr 2>/dev/null
    echo "$effect" >/sys/class/led_anim/effect_lr 2>/dev/null
    
}

set_led_color() {
    local r=$1
    local g=$2
    local b=$3
    
    
    if [ ! -w "/sys/class/led_anim/frame_hex" ]; then
        log_message "Warning: Cannot access LED frame"
        chmod a+w /sys/class/led_anim/*
    fi
    
    local valstr=$(printf "%02X%02X%02X" $r $g $b)
    echo "$valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr $valstr " \
    "$valstr $valstr $valstr $valstr $valstr $valstr $valstr" >/sys/class/led_anim/frame_hex
    
    # local valstr=$(printf "%02X%02X%02X" $r $g $b)
    # yes "$valstr" | head -n 24 | tr '\n' ' ' | sed 's/ *$//' > /sys/class/led_anim/frame_hex
}

# Check if a file exists and is executable
check_executable() {
    local file=$1
    if [ ! -f "$file" ]; then
        log_message "Warning: $file not found"
        return 1
    fi
    if [ ! -x "$file" ]; then
        log_message "Warning: $file not executable"
        return 1
    fi
    return 0
}

log_message "Starting kill_apps.sh"


if pgrep -f "drastic" > /dev/null; then
    sigkill_countdown=10
    log_message "Drastic detected -> Sigkill countdown = ${sigkill_countdown}s"
fi

# Check button state
"$SCRIPTS_DIR/button_state.sh" MENU
exit_code=$?
if [ $exit_code -eq 10 ]; then # No shutdown and force current app to exit.
    log_message "MENU button pressed - kill current app."
    
    
    # Hardware feedback
    vibrate_short &
    
    # On screen feedback
    /usr/trimui/osd/show_default_msg_short.sh "Force App Exit" &
    
    # Check if smartledd is running before killing it
    if pgrep -f smartledd >/dev/null; then
        SMARTLEDD_WAS_RUNNING=1
        pkill -9 smartledd
    else
        SMARTLEDD_WAS_RUNNING=0
    fi
    # Led feedback
    set_led_animation "FF0000" 5 50 5 & # 3 fast red blinking
    
    # Execute cmd_to_run_killer in background for immediate response
    if check_executable "$SCRIPTS_DIR/cmd_to_run_killer.sh"; then
        "$SCRIPTS_DIR/cmd_to_run_killer.sh" $sigkill_countdown
    fi
    
    if [ "$SMARTLEDD_WAS_RUNNING" -eq 1 ]; then
        "/mnt/SDCARD/Apps/LedControl.pak/smartledd" &
    fi
    
    log_message "Force exit app completed"
    sync
    exit 0
fi

# Normal shutdown sequence
log_message "Starting normal shutdown sequence"

# Set yellow LED to indicate shutdown in progress
set_led_color 255 255 0 &
vibrate_short &

# Prepare shutdown screen
log_message "Preparing shutdown screen"
Current_Theme=""
if command -v systemval >/dev/null 2>&1; then
    Current_Theme=$(/usr/trimui/bin/systemval theme 2>/dev/null)
fi

Shutdown_Screen=""
Shutdown_Text="Shutting down..."

if [ -n "$Current_Theme" ] && [ -f "$Current_Theme/skin/shutdown.png" ]; then
    Shutdown_Screen="$Current_Theme/skin/shutdown.png"
    Shutdown_Text=" "
    log_message "Using theme shutdown screen"
    elif [ -n "$Current_Theme" ] && [ -f "$Current_Theme/skin/bg.png" ]; then
    Shutdown_Screen="$Current_Theme/skin/bg.png"
    log_message "Using theme background"
    elif [ -f "$TRIMUI_DIR/res/crossmix-os/bg-info.png" ]; then
    Shutdown_Screen="$TRIMUI_DIR/res/crossmix-os/bg-info.png"
    log_message "Using default background"
else
    log_message "Warning: No shutdown screen found"
fi

# Display shutdown screen
if [ -n "$Shutdown_Screen" ] && check_executable "$SCRIPTS_DIR/infoscreen.sh"; then
    "$SCRIPTS_DIR/infoscreen.sh" -i "$Shutdown_Screen" -m "$Shutdown_Text" -fs 100 -t 1 &
    log_message "Shutdown screen displayed"
else
    log_message "Cannot display shutdown screen"
fi

# Red LED animation during shutdown
set_led_animation "FF0000" 10 500 1 &

# Backup current script
log_message "Backing up cmd_to_run.sh"
if [ -f "/tmp/cmd_to_run.sh" ]; then
    cp /tmp/cmd_to_run.sh "$TRIMUI_DIR/app/" 2>/dev/null || log_message "Warning: Could not backup cmd_to_run.sh"
fi
sync

# Kill background processes
log_message "Stopping background processes"
pkill -9 preload.sh 2>/dev/null  # avoid removing cmd_to_run.sh during direct shutdown from resume
pkill -9 runtrimui.sh 2>/dev/null

# Execute cmd_to_run_killer for clean process termination
log_message "Executing cmd_to_run_killer $sigkill_countdown for process cleanup"
if check_executable "$SCRIPTS_DIR/cmd_to_run_killer.sh"; then
    "$SCRIPTS_DIR/cmd_to_run_killer.sh" $sigkill_countdown
    log_message "Process cleanup completed"
else
    log_message "Warning: cmd_to_run_killer.sh not available - some processes may remain"
fi

# Play shutdown sound
aplay "$TRIMUI_DIR/res/sound/PowerOff.wav" -d 1

sync

# Execute system shutdown
if check_executable "$SYSTEM_DIR/bin/shutdown"; then
    log_message "Executing system shutdown"
    "$SYSTEM_DIR/bin/shutdown"
else
    log_message "Warning: system shutdown not available"
fi

sleep 8
log_message "Initiating fallback poweroff"
poweroff
