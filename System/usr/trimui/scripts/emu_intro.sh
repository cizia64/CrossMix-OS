#!/bin/sh

CurrentTheme=$(/usr/trimui/bin/systemval theme)
EmuPath="${0#/mnt/SDCARD/Emus/}"
EmuPath="${EmuPath%%/*}"
IntroSound="${CurrentTheme}sound/intro_$EmuPath.wav"

# for compatibility, default led effect
sh "/mnt/SDCARD/Emus/$EmuPath/effect.sh" &

# playing the default sound for the current emulator
if [ -f "$IntroSound" ]; then
  aplay "$IntroSound" -d 1 &
fi
