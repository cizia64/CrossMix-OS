FILE="/bin/busybox"
LIMIT=819200
FILESIZE=$(ls -l "$FILE" | awk '{print $5}')
# Install new busybox from PortMaster, credits : https://github.com/kloptops/TRIMUI_EX

if [ "$FILESIZE" -lt "$LIMIT" ]; then
  cp -vf /bin/busybox /bin/busybox.bak

  cp -vf /mnt/SDCARD/System/usr/trimui/scripts/busybox /bin/busybox

  ln -vs "/bin/busybox" "/bin/bash"

  # Create missing busybox commands
  for cmd in $(busybox --list); do
    # Skip if command already exists or if it's not suitable for linking
    if [ -e "/bin/$cmd" ] || [ -e "/usr/bin/$cmd" ] || [ "$cmd" = "sh" ]; then
      continue
    fi

    # Create a symbolic link
    ln -vs "/bin/busybox" "/usr/bin/$cmd"
  done

  # Fix weird libSDL location
  for libname in /usr/trimui/lib/libSDL*; do
    linkname="/usr/lib/$(basename "$libname")"
    if [ -e "$linkname" ]; then
      continue
    fi
    ln -vs "$libname" "$linkname"
  done

fi
