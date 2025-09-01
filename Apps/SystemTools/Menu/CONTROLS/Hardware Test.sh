#!/bin/bash

pkill -f hwt

if [ "$#" -gt 0 ]; then
 ./hwt "$@"
else
  progdir=$(dirname "$0")
  cd $progdir
  ./hwt
fi