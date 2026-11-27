#!/bin/sh
# Run from the repository root with Docker and trimui-bigpicture:dev installed.
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
docker run --rm -v "$repo:/workspace" trimui-bigpicture:dev sh -c '
  set -eu
  cd /workspace/System/resources/usb_storage
  trimui-gcc -std=c11 -O2 -Wall -Wextra -Werror usb_exit_watchdog.c -o usb_exit_watchdog
'
