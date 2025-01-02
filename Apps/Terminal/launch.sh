#!/bin/bash

progdir=$(dirname "$0")
export LD_LIBRARY_PATH="$progdir/lib:$LD_LIBRARY_PATH"
$progdir/TermSP -k -e "$progdir/screen" -c "$progdir/.screenrc" "$@"
