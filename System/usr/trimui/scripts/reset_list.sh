#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:$PM_DIR:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Check if the RomDir parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <RomDir or FullPath>"
    exit 1
fi

InputPath="$1"
JsonFile="/mnt/romwinidx.json"

# Determine if InputPath is a directory name or full path
if [ -d "$InputPath" ]; then
    RomDir="$InputPath"
    RomDirBase="$(basename "$RomDir")"
else
    RomDir="/mnt/SDCARD/Roms/$InputPath"
    RomDirBase=$InputPath
fi

# Check if the JSON file exists
if [ ! -f "$JsonFile" ]; then
    echo "Error: The file $JsonFile does not exist."
    exit 1
fi

# Modify the JSON file using jq
tmpfile=$(mktemp)
jq --arg RomDirBase "$RomDirBase" '
    .list |= map(
        if (.rompath | contains($RomDirBase)) then
            .end = (.start + 5)
        else
            .
        end
    )
' "$JsonFile" >"$tmpfile"

# Check if jq succeeded
if [ $? -eq 0 ]; then
    mv "$tmpfile" "$JsonFile"
    echo "Successfully updated rompaths containing \"$RomDir\" or \"$RomDirBase\"."
else
    echo "Error: Failed to update the JSON file."
    rm -f "$tmpfile"
    exit 1
fi

# Remove cache file if it exists
CacheFile="$RomDir/${RomDirBase}_cache7.db"
if [ -f "$CacheFile" ]; then
    rm -f "$CacheFile"
    echo "Removed cache file: $CacheFile"
else
    echo "No cache file found for $RomDir."
fi
