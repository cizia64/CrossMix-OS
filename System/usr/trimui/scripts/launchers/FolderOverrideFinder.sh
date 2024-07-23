subdir_count=$(echo "$1" | awk -F'/Roms/' '{print $2}' | awk -F'/' '{print NF-1}') # Count the number of slashes in the rest of the path

if [ "$subdir_count" -gt 1 ]; then
    if [ -z "$2" ]; then # the override config file is not already defined
        echo "############### Folder Overrride Finder ###############"
        first_subdir=$(echo "$1" | awk -F'/Roms/' '{print $2}' | cut -d'/' -f1) # Use awk to extract the part of the path after "/mnt/SDCARD/Roms/" to the next "/".
        echo "Subdirectory from $first_subdir detected !"

        # We try to find the config folder :
        core_filename=$(grep '^[[:space:]]*HOME=' "$0" | grep '_libretro\.so' | sed -E 's/.*cores\/([^\/]+\.so).*/\1/')  # we find the core filename in the launch script itself
        core_folder=$(grep -m 1 "$core_filename" /mnt/SDCARD/System/usr/trimui/scripts/core_folders.csv | cut -d';' -f2) # we use a core database which indicates for a core filename the corresponding config path
        echo "The core folder for $core_filename is: $core_folder"

        if [ -f "/mnt/SDCARD/RetroArch/.retrorch/config/$core_folder/$first_subdir.cfg" ]; then
            FolderOverride="/mnt/SDCARD/RetroArch/.retroarch/config/$core_folder/$first_subdir.cfg"
        else
            # we try to find the folder override without the core database
            result=$(find /mnt/SDCARD/RetroArch/.retroarch/config/ -name "$first_subdir.cfg")
            num_lines=$(echo "$result" | wc -l)

            if [ $num_lines -eq 1 ]; then
                FolderOverride="$result"
            else
                # if we find multiple folder override config files, we try to find the right one depending the core name
                core_name=$(grep '^[[:space:]]*HOME=' "$0" | grep '_libretro\.so' | sed -E 's/.*cores\/([^\/]+)_libretro\.so.*/\1/' | cut -d'_' -f1)
                result=$(echo "$result" | grep -i "$core_name/")
                num_lines=$(echo "$result" | wc -l)
                if [ $num_lines -eq 1 ]; then
                    FolderOverride="$result"
                else
                    if [ $num_lines -ne 0 ]; then
                        # less restrictive comparison  :
                        result=$(echo "$result" | grep -i "$core_name")
                        num_lines=$(echo "$result" | wc -l)
                        if [ $num_lines -eq 1 ]; then
                            FolderOverride="$result" #  (we avoid to select one by default : FolderOverride=$(echo "$result" | head -n 1))
                        elif [ $num_lines -gt 1 ]; then
                            echo "Multiple possibilities found, none selected"
                        fi

                    fi
                fi
            fi
        fi

        if [ ! -z "$FolderOverride" ]; then

            echo "Folder override found: $FolderOverride"
            echo "#######################################################"
            source "$0" "$1" --appendconfig "$FolderOverride"
            exit
        else
            echo "Folder override not found"
            echo "#######################################################"
        fi

    fi
else
    echo "No subdirectory detected."
fi
