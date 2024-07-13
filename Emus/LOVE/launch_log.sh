#!/bin/sh

EMU_DIR=$(dirname "$0")

export LOVE_GRAPHICS_USE_OPENGLES=1
export SDL_VIDEO_GL_DRIVER=libGLESv2.so

cd $(dirname "$1")
subname=$(basename "$PWD")
echo subname=$subname

file=$(basename "$1")
title=${file%.*}

#10,11 can share same lib directory structure, different libname, but 9 will conflict with 10 .
if [ "$subname" == "0.10.2" ]; then
  ver=".10.2"
elif [ "$subname" == "0.9.2" ]; then
  echo subname=$subname PWD=$PWD
fi

# Each a gptk if exists or use specified one, not good idea
#gptk=" -c $EMU_DIR/love.gptk"
if [ -f ${title}.gptk ]; then 
   gptk=" -c ./${title}.gptk"
fi

PATH=$PWD:$EMU_DIR:$PATH
export LD_LIBRARY_PATH=$PWD/libs:$EMU_DIR/libs:$LD_LIBRARY_PATH
bin=love${ver}
echo bin=$bin LD_LIBRARY_PATH=$LD_LIBRARY_PATH PATH=$PATH

echo gptokeyb -k $bin $gptk 
gptokeyb -k $bin $gptk &
${bin} "$*" 2>&1 | tee -a ./log.txt
$ESUDO kill -9 $(pidof gptokeyb)
