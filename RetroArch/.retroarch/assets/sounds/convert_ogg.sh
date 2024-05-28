# Script to convert to OGG, rename to lowercase and copy chosen sounds
# requires ffmpeg and libvorbis/libogg
SOUNDS="OK.wav CANCEL.wav BGM.wav UP.wav DOWN.wav LAUNCH.wav NOTICE.wav NOTICE_BACK.wav"

mkdir -p ../../sounds
for src in $SOUNDS; do
        export dest=`echo $src | sed "s/.wav/.ogg/"`
        export dest=`echo "$dest" | tr '[:upper:]' '[:lower:]'`
        echo "$src -> $dest"
        
        ffmpeg -i $src -acodec libvorbis ../../sounds/$dest
done
        
cp Licence.txt ../../sounds/Licence.txt
