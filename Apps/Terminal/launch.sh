#!/bin/bash

progdir=$(dirname "$0")
export LD_LIBRARY_PATH="$progdir/lib:$LD_LIBRARY_PATH"
display=$(fbset | grep ^mode | cut -d "\"" -f 2)
[ "$display" != "1280x720-64" ] && BRICK_FLAG="-d brick"
$progdir/TermSP -k $BRICK_FLAG -e "$progdir/screen" -c "$progdir/.screenrc" "$@"
