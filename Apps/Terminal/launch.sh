#!/bin/bash

progdir=$(dirname "$0")
export LD_LIBRARY_PATH="$progdir/lib:$LD_LIBRARY_PATH"

[ $# -eq 0 ] && FLAGS="-k"

$progdir/TermSP $FLAGS "$@"
