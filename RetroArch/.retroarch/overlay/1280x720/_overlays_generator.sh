#!/bin/bash
# To create a new overlay, first create a core override, a content directory override or a game override.
# Then run this script to create the correponding overlay config files
# Then add your own png files with the same names as the created config files. 
# A good way to create your own overlay is to make a screenshot in game then work the overlay around this screenshot.
# Last step run "System Tools" app and in "Emulators -> Screen ration & overlays" select "overlay_max-ratio" or "overlay_pixel-perfect"
# 

# Directory containing .cfg files
cfg_dir="/mnt/SDCARD/RetroArch/.retroarch/config/"

# Directory to create new files
overlay_dir="/mnt/SDCARD/RetroArch/.retroarch/overlay/"

# Initialize counters
cfg_count=0
not_replaced_count=0

# Recursively search for .cfg files in cfg_dir
while IFS= read -r -d '' cfg_file; do
    # Extract the prefix of the file name (without the .cfg extension)
    prefix=$(basename "$cfg_file" .cfg)
	prefix=${prefix// /_}

    # Path to the _max-ratio.cfg and _pixel-perfect.cfg files
    max_ratio_file="${overlay_dir}${prefix}_max-ratio.cfg"
    pixel_perfect_file="${overlay_dir}${prefix}_pixel-perfect.cfg"

    # Check if _max-ratio.cfg file already exists
    if [ ! -e "$max_ratio_file" ]; then
        # Add configurations to _max-ratio.cfg
        echo "overlays = 1" > "$max_ratio_file"
        echo "overlay0_overlay = ${prefix}_max-ratio.png" >> "$max_ratio_file"
        echo "overlay0_full_screen = true" >> "$max_ratio_file"
        echo "overlay0_descs = 0" >> "$max_ratio_file"
    else
         not_replaced_count=$((not_replaced_count + 1))
    fi

    # Check if _pixel-perfect.cfg file already exists
    if [ ! -e "$pixel_perfect_file" ]; then
        # Add configurations to _pixel-perfect.cfg
        echo "overlays = 1" > "$pixel_perfect_file"
        echo "overlay0_overlay = ${prefix}_pixel-perfect.png" >> "$pixel_perfect_file"
        echo "overlay0_full_screen = true" >> "$pixel_perfect_file"
        echo "overlay0_descs = 0" >> "$pixel_perfect_file"
    fi

    # Increment the count of .cfg files found
     cfg_count=$((cfg_count + 1))

    # Display a message for each created file
    echo "Files created for $prefix :"
    echo "$max_ratio_file"
    echo "$pixel_perfect_file"
done < <(find "$cfg_dir" -type f -name '*.cfg' ! -path "*VecX*" -print0)

# Display the total number of .cfg files found
echo "Total number of .cfg files found: $cfg_count"

# Display the number of files not replaced
echo "Number of files not replaced: $not_replaced_count"
