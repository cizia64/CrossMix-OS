#!/bin/sh
export PATH="/mnt/SDCARD/System/usr/trimui/scripts/:/mnt/SDCARD/System/bin:$PM_DIR:${PATH:+:$PATH}"
export LD_LIBRARY_PATH="/usr/trimui/lib:/mnt/SDCARD/System/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Check if the RomDir parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <RomDir or FullPath>"
    exit 1
fi

InputPath="$1"

############################### update romwinidx.json ###############################

JsonFile="/mnt/romwinidx.json"

if [ -d "$InputPath" ]; then
    RomDir="$InputPath"
    RomDirBase="$(basename "$RomDir")"
else
    RomDir="/mnt/SDCARD/Roms/$InputPath"
    RomDirBase=$InputPath
fi

if [ -f "$JsonFile" ]; then
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

    if [ $? -eq 0 ]; then
        mv "$tmpfile" "$JsonFile"
        echo "Successfully updated romwinidx.json containing \"$RomDirBase\"."
    else
        echo "Error: Failed to update the JSON file."
        rm -f "$tmpfile"
    fi

else
    echo "Error: The file $JsonFile does not exist."
fi

############################### update state.json ###############################

stateFile="/tmp/state.json"
if [ -f "$stateFile" ]; then
    tmpfile=$(mktemp)

    jq --arg InputPath "$InputPath" '
        .list |= map(
            if (.emulaunch? and (.emulaunch | type == "string") and (.emulaunch | contains($InputPath))) then
                .pageend = (.pagestart + 5)
            else
                .
            end
        )
    ' "$stateFile" >"$tmpfile"

    if [ $? -eq 0 ]; then
        mv "$tmpfile" "$stateFile"
        echo "Successfully updated state.json."
    else
        echo "Error: Failed to update state.json."
        rm -f "$tmpfile"
    fi
fi

############################### Remove cache file if it exists ###############################

CacheFile="$RomDir/${RomDirBase}_cache7.db"
if [ -f "$CacheFile" ]; then
    rm -f "$CacheFile"
    echo "Removed cache file: $CacheFile"
else
    echo "No cache file found for $RomDir."
fi
