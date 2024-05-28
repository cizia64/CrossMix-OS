#!/bin/sh

# MonoChrome SVG to PNG Converter
#
# Will update the given icon from its SVG to its PNG.
#
# Requires Inkscape to be installed.
#
# ./convert.sh THEME ICON
#
# Parameters
# - THEME   Which theme to act on.
# - ICON    Which icon to conver from an SVG to a PNG.
#
# Example
#
#     ./convert.sh monochrome battery-full
#     ./convert.sh flatui DOS

cd -- "$(cd -- "$(dirname -- "$0")" && pwd -P)"

inkscape -z -e "$1/png/$2.png" -w 256 -h 256 "../src/xmb/$1/$2.svg"
