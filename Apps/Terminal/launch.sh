#!/bin/bash

progdir=$(dirname "$0")
LD_LIBRARY_PATH="$progdir/lib:$LD_LIBRARY_PATH"
res_dir=$progdir/resources

display=$(fbset | grep ^mode | cut -d "\"" -f 2)
[ "$display" != "1280x720-64" ] && BRICK_FLAG="-d brick"

$progdir/TermSP -k $BRICK_FLAG -f "$res_dir/Hack-Regular.ttf" -b "$res_dir/Hack-Bold.ttf" -s22 -e "sh" "$@"
