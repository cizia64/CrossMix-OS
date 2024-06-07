#!/bin/sh
echo "=======================================================================:::"
echo $0 $*
source /mnt/SDCARD/System/usr/trimui/scripts/FolderOverrideFinder.sh
RA_DIR=/mnt/SDCARD/RetroArch
EMU_DIR=/mnt/SDCARD/Emus/MD
cd $RA_DIR/

$EMU_DIR/cpufreq.sh
$EMU_DIR/cpuswitch.sh

RomFullPath=$1

echo "*-*-*--*-*-*-*-*-*-*-*-*-*-*-*-*-*-* $2"

# Utilisation de awk pour extraire la partie du chemin après "/mnt/SDCARD/Roms/" jusqu'au prochain "/"
first_subdir=$(echo "$RomFullPath" | awk -F'/mnt/SDCARD/Roms/' '{print $2}' | cut -d'/' -f1)

# Compter le nombre de barres obliques dans le reste du chemin
subdir_count=$(echo "$RomFullPath" | awk -F'/mnt/SDCARD/Roms/' '{print $2}' | awk -F'/' '{print NF-1}')

# Si le nombre de sous-répertoires est supérieur à 1, alors c'est un sous-sous-répertoire
if [ "$subdir_count" -gt 1 ] && [ -z "$2" ]; then
    echo "Sous-répertoire détecté !"
	

	
	
	picodrive=$(grep -v '^#' $0 | grep '_libretro\.so' | awk -F'/' '{ for (i=1; i<=NF; i++) if ($i == "picodrive_libretro.so") {print $(i-1)} }')
	echo "####################### $picodrive"
	
	
result=$(find /mnt/SDCARD/RetroArch/.retroarch/config/ -name "$first_subdir.cfg")

num_lines=$(echo "$result" | wc -l)

if [ $num_lines -eq 1 ]; then
    FolderOverride="$result"
else
    core_name=$(grep '^[[:space:]]*HOME=' "$0" | grep '_libretro\.so' | sed -E 's/.*cores\/([^_]+)_libretro\.so.*/\1/')
    core_config=$(echo "$result" | grep -i "$core_name")

    if [ -z "$core_config" ]; then
        # Si core_config n'est pas trouvé, prendre la première ligne de "result"
        FolderOverride=$(echo "$result" | head -n 1)
    else
        FolderOverride="$core_config"
    fi
	
	
	echo core_name $core_name
	echo core_line $core_line
	echo FolderOverride $FolderOverride
	echo "We have done itttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt!"
	
fi


	
	
	
    source "$0" "$1" --appendconfig "$FolderOverride"
	
	
	
	
	
	
	
	
    exit
fi


echo "Premier sous-répertoire après 'Roms': $first_subdir"



echo "?????????????????????????????????????????"
echo "HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so $*"
echo "HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so --appendconfig /mnt/SDCARD/RetroArch/.retroarch/config/PicoDrive/MD.cfg $2"
echo "?????????????????????????????????????????"

# HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so "$1" $2
		HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so "$@"
# eval "HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so $*"
# HOME=$RA_DIR/ $RA_DIR/ra64.trimui -v $NET_PARAM -L $RA_DIR/.retroarch/cores/picodrive_libretro.so --appendconfig /mnt/SDCARD/RetroArch/.retroarch/config/PicoDrive/MD.cfg "$2"


#HOME=$RA_DIR/ $RA_DIR/retroarch -v $NET_PARAM -L $RA_DIR/.retroarch/cores/genesis_plus_gx_libretro.so "$@"