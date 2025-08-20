#!/bin/sh
# Silent background OTA checker for CrossMix-OS
# - Runs at boot in background
# - No UI output; logs to $updatedir/ota_check.log
# - Detects newer major/minor versions and sets flags consumed by UI scripts

# Common env, paths, helpers
source /mnt/SDCARD/System/usr/trimui/scripts/update_common.sh

# Set to 1 to write logs to file, 0 to print logs to console
LOG_TO_FILE=0

LOG_FILE="$updatedir/ota_check.log"
RELEASE_META="$updatedir/available_release.json"
HOTFIX_META="$updatedir/available_hotfix.json"
STAMP_FILE="$updatedir/ota_check_last_run.txt"

mkdir -p "$updatedir"

log() {
    ts="$(date +'%Y-%m-%d %H:%M:%S') - $*"
    if [ "${LOG_TO_FILE:-1}" = "1" ]; then
        echo "$ts" >>"$LOG_FILE"
    else
        echo "$ts"
    fi
}

# Convert x.y.z[.w][-suffix] into comparable integer
get_version() {
    echo "$1" | tr -d '[:alpha:]' | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

has_ip() {
    ip route get 1 2>/dev/null | awk '/src/ {print $NF; exit}'
}

can_reach_github() {
    wget -q --spider https://github.com >/dev/null 2>&1
}

write_result_json() {
    # $1: name, $2: url, $3: size_bytes, $4: created_at
    cat >"$RELEASE_META" <<EOF
{
  "name": "$1",
  "url": "$2",
  "size": $3,
  "created_at": "$4"
}
EOF
}

# Check major release availability from GitHub releases
check_major_release() {
    release_json=$(curl -k -s "https://api.github.com/repos/$GITHUB_REPOSITORY/releases/latest")
    if echo "$release_json" | grep -q '"message": "Not Found"'; then
        log "No GitHub releases found."
        rm -f "$RELEASE_META"
        exit 1
    fi

    asset=$(echo "$release_json" | jq '.assets[]? | select((.name | contains("CrossMix-OS_v")) and (.name | endswith(".zip")))')
    if [ -z "$asset" ]; then
        log "Github API Request has failed or latest release has no CrossMix-OS_v*.zip asset."
        rm -f "$RELEASE_META"
        exit 1
    fi

    url=$(echo "$asset" | jq -r '.browser_download_url')
    name=$(echo "$asset" | jq -r '.name')
    size=$(echo "$asset" | jq -r '.size')
    created=$(echo "$asset" | jq -r '.created_at')

    release_full_version="${name#CrossMix-OS_v}"
    release_full_version="${release_full_version%.zip}"
    remote_version_core="${release_full_version%-dev*}"

    local_full_version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null)
    local_version_core="${local_full_version%-dev*}"

    if [ -z "$local_full_version" ]; then
        log "Local version missing; flagging update $release_full_version."
        write_result_json "$name" "$url" "$size" "$created"
        sync
        return 0
    fi

    local_v=$(get_version "$local_version_core")
    remote_v=$(get_version "$remote_version_core")

    if [ "$local_v" -lt "$remote_v" ] || { [ "$local_v" -eq "$remote_v" ] && [ "$local_full_version" != "$release_full_version" ]; }; then
        rm -f "$HOTFIX_META"
        write_result_json "$name" "$url" "$size" "$created"
        log "Update available: $local_full_version -> $release_full_version ($size bytes)."
        echo -e "{ \"type\":\"info\", \"size\":2, \"duration\":5000, \"x\":670, \"y\":640,  \"message\":\"       CrossMix v$release_full_version available.\",  \"icon\":\"\" }" >/tmp/trimui_osd/osd_toast_msg

        sync
        return 0
    fi

    rm -f "$RELEASE_META"
    return 1
}

# Check hotfix availability for a given base version (e.g., 1.3.0)
check_hotfix() {
    base_version="$1"
    url="https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/_assets/hotfixes/CrossMix-OS_v${base_version}.sh"

    if ! wget -q --spider "$url" >/dev/null 2>&1; then
        rm -f "$HOTFIX_META"
        return 1
    fi

    content=$(curl -k -s "$url") || {
        rm -f "$HOTFIX_META"
        return 1
    }

    remote_hotfix=$(echo "$content" | sed -n 's/^Remote_HotfixVersion="\(.*\)"/\1/p' | head -n1)
    remote_date=$(echo "$content" | sed -n 's/^Remote_HotfixDate="\(.*\)"/\1/p' | head -n1)

    [ -z "$remote_hotfix" ] && {
        rm -f "$HOTFIX_META"
        return 1
    }

    if [ -f /mnt/SDCARD/System/usr/trimui/crossmix-hotfix-version.txt ]; then
        local_hotfix=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-hotfix-version.txt)
    else
        # default to .0 of same width as remote last digit
        local_hotfix=$(echo "$remote_hotfix" | sed 's/\(.*\).$/\10/')
    fi

    if [ "$(echo "$remote_hotfix" | tr -d '.')" -gt "$(echo "$local_hotfix" | tr -d '.')" ]; then
        cat >"$HOTFIX_META" <<EOF
{
  "for_version": "$base_version",
  "remote_hotfix": "$remote_hotfix",
  "local_hotfix": "$local_hotfix",
  "date": "$remote_date",
  "script": "$url"
}
EOF
        sync
        return 0
    fi

    rm -f "$HOTFIX_META"
    return 1
}

main() {

    # Quick network check
    if [ -z "$(has_ip)" ]; then
        log "No IP at boot; skipping OTA check."
        exit 1
    fi
    if ! can_reach_github; then
        log "GitHub API not reachable; skipping OTA check."
        exit 1
    fi

    # Run at most once per day unless --force
    TODAY="$(date +%Y-%m-%d)"
    if [ "$1" != "--force" ]; then
        last_run_date=$(cat "$STAMP_FILE" 2>/dev/null)
        if [ "$last_run_date" = "$TODAY" ]; then
            log "Already ran today ($TODAY); skipping."
            exit 0
        fi
        echo "$TODAY" >"$STAMP_FILE"
        sync
    else
        log "Force run requested; bypassing daily guard."
    fi

    # Check major release first
    if check_major_release; then
        exit 0
    fi

    # No major update; check hotfix
    base_version=$(cat /mnt/SDCARD/System/usr/trimui/crossmix-version.txt 2>/dev/null)
    local_version_core="${base_version%-dev*}"
    rm -f "$RELEASE_META"
    log "No major update. Checking hotfix for $local_version_core."
    if check_hotfix "$local_version_core"; then
        log "Hotfix $remote_hotfix available for base $local_version_core."
        echo -e "{ \"type\":\"info\", \"size\":2, \"duration\":5000, \"x\":670, \"y\":640,  \"message\":\"CrossMix Hotfix $remote_hotfix available.\",  \"icon\":\"\" }" >/tmp/trimui_osd/osd_toast_msg
        exit 0
    fi

    log "No hotfix available."
    exit 1
}

main "$@"
