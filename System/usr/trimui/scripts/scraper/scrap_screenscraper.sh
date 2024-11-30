#!/bin/sh
#echo $0 $*    # for debugging

if [ -z "$1" ]; then
    echo -e "\nusage : scrap_screenscraper.sh emu_folder_name [rom_name]\nexample : scrap_screenscraper.sh SFC\n"
    exit
fi

export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:$LD_LIBRARY_PATH"
export PATH="/mnt/SDCARD/System/bin:$PATH"

echo performance >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor


romcount=0
Scrap_Success=0
Scrap_Fail=0
Scrap_notrequired=0

CurrentSystem=$1
CurrentRom="$2"

Screenscraper_information() {
    # clear

    cat <<EOF
==========================================================================================

For better scraping performance set your ScreenScraper account in the file :
/mnt/SDCARD/System/etc/scraper.json
 
Number of downloads per day and speed increases with participation in the 
database or with donations.

All is detailed at : 
https://www.screenscraper.fr/faq.php

Quota counters are reset every day at midnight (French time - UTC+2)

==========================================================================================

EOF

    # read -n 1 -s -r -p "Press A to continue"
    # clear
}

# Function to search on screenscraper with retry logic
search_on_screenscraper() {
    local retry_count=0
    local max_retries=5

    while true; do
        # TODO : managing multithread for users who have it.
        api_result=$(curl -k -s "$url")
        Head_api_result=$(echo "$api_result" | head -n 1)

        # Don't check art if max threads for leechers is used
        if echo "$Head_api_result" | grep -q "The maximum threads"; then
            if [ "$retry_count" -ge "$max_retries" ]; then
                echo "The Screenscraper API is too busy for non-users. Please try again later (or register)."
                echo "Press any key to finish"
                # read dummy
                break
            else
                let retry_count++
                echo "Retrying API call ($retry_count / $max_retries)..."
                echo "Registering a Screenscraper account can help !"
                sleep_duration=$((5 + retry_count))
                sleep "$sleep_duration"
            fi
        else
            break # we have a result, we exit
        fi
    done

    # Don't check art if screenscraper is closed
    if echo "$Head_api_result" | grep -q "API closed"; then
        echo -e "${RED}The Screenscraper API is currently down, please try again later.{NONE}"
        let Scrap_Fail++
        # read -n 1 -s -r -p "Press A to exit"
        return
    fi

    # Don't check art after a failed curl request
    if [ -z "$Head_api_result" ]; then
        echo -e "${RED}Request failed${NONE}"
        echo "$(date '+%Y-%m-%d %Hh%M') : Request failed for ${romNameTrimmed}"
        let Scrap_Fail++
        return
    fi

    # Don't check art if screenscraper can't find a match
    if echo "$Head_api_result" | grep -q "^Erreur"; then
        echo -e "${RED}No match found${NONE}"
        echo "$(date '+%Y-%m-%d %Hh%M') : Couldn't find a match for ${romNameTrimmed}"
        return
    fi

    gameIDSS=$(echo "$api_result" | jq -r '.response.jeu.id')
    if ! [ "$gameIDSS" -eq "$gameIDSS" ] 2>/dev/null; then
        gameIDSS=$(echo "$api_result" | jq -r '.jeu.id')
    fi
}


get_ssSystemID() {
  case $1 in
    ADVMAME)            ssSystemID="75";;    # Mame
    AMIGA)              ssSystemID="64";;    # Commodore Amiga
    AMIGACD)            ssSystemID="134";;   # Commodore Amiga CD
    AMIGACDTV)          ssSystemID="129";;   # Commodore Amiga CD
    ARCADE)             ssSystemID="75";;    # Mame
    ARDUBOY)            ssSystemID="263";;   # Arduboy
    ATARI2600)          ssSystemID="26";;    # Atari 2600
    ATARIST)            ssSystemID="42";;    # Atari ST
    ATOMISWAVE)         ssSystemID="53";;    # Atari ST
    COLECO)             ssSystemID="183";;   # Coleco
    COLSGM)             ssSystemID="183";;   # Coleco
    C64)                ssSystemID="66";;    # Commodore 64
    CPC)                ssSystemID="65";;    # Amstrad CPC
    CPET)               ssSystemID="240";;   # Commodore PET
    CPLUS4)             ssSystemID="99";;    # Commodore Plus 4
    CPS1)               ssSystemID="6";;     # Capcom Play System
    CPS2)               ssSystemID="7";;     # Capcom Play System 2
    CPS3)               ssSystemID="8";;     # Capcom Play System 3
    DAPHNE)             ssSystemID="49";;    # Daphne
    DC)                 ssSystemID="23";;    # dreamcast
    DOS)                ssSystemID="135";;   # DOS
    EASYRPG)            ssSystemID="231";;   # EasyRPG
    EBK)                ssSystemID="93";;    # EBK
    ATARI800)           ssSystemID="43";;    # Atari 800
    CHANNELF)           ssSystemID="80";;    # Fairchild Channel F
    FBA2012)            ssSystemID="75";;    # FBA2012
    FBALPHA)            ssSystemID="75";;    # FBAlpha
    FBNEO)              ssSystemID="";;      # FBNeo (Empty)
    FC)                 ssSystemID="3";;     # NES (Famicom)
    FDS)                ssSystemID="106";;   # Famicom Disk System
    ATARI5200)          ssSystemID="40";;    # Atari 5200
    GB)                 ssSystemID="9";;     # Game Boy
    GBA)                ssSystemID="12";;    # Game Boy Advance
    GBC)                ssSystemID="10";;    # Game Boy Color
    GG)                 ssSystemID="21";;    # Sega Game Gear
    GW)                 ssSystemID="52";;    # Nintendo Game & Watch
    INTELLIVISION)      ssSystemID="115";;   # Intellivision
    JAGUAR)             ssSystemID="27";;    # Atari Jaguar
    LOWRESNX)           ssSystemID="244";;   # LowRes NX
    LUTRO)              ssSystemID="206";;   # Lutro
    LYNX)               ssSystemID="28";;    # Atari Lynx
    MAME)               ssSystemID="75";;    # Mame 2000
    MAME2003PLUS)       ssSystemID="75";;    # Mame 2003
    MAME2010)           ssSystemID="75";;    # Mame 2003
    MBA)                ssSystemID="75";;    # MBA
    MD)                 ssSystemID="1";;     # Sega Genesis (Mega Drive)
    MDMSU)              ssSystemID="1";;     # Sega Genesis (Mega Drive) Hacks
    MEGADUCK)           ssSystemID="90";;    # Megaduck
    MS)                 ssSystemID="2";;     # Sega Master System
    MSX)                ssSystemID="113";;   # MSX
    MSX2)               ssSystemID="116";;   # MSX
    N64)                ssSystemID="14";;    # Nintendo 64
    N64DD)              ssSystemID="122";;   # Nintendo 64DD
    NAOMI)              ssSystemID="56";;    # Sega Naomi
    NDS)                ssSystemID="15";;    # NDS
    NEOCD)              ssSystemID="70";;    # Neo Geo CD
    NEOGEO)             ssSystemID="142";;   # Neo Geo AES
    NGP)                ssSystemID="25";;    # Neo Geo Pocket
    NGC)                ssSystemID="82";;    # Neo-geo Pocket Color
    ODYSSEY)            ssSystemID="104";;   # Videopac / Magnavox Odyssey 2
    OPENBOR)            ssSystemID="214";;   # OpenBOR
    PALMOS)             ssSystemID="219";;   # Palm
    PANASONIC)          ssSystemID="29";;    # 3DO
    PCE)                ssSystemID="31";;    # NEC TurboGrafx-16 / PC Engine
    PCECD)              ssSystemID="114";;   # NEC TurboGrafx-CD
    PC88)               ssSystemID="221";;   # NEC PC-8000 & PC-8800 series / NEC PC-8801
    PCFX)               ssSystemID="72";;    # NEC PC-FX
    PC98)               ssSystemID="208";;   # NEC PC-98 / NEC PC-9801
    PICO)               ssSystemID="234";;   # PICO
    POKEMINI)           ssSystemID="211";;   # PokeMini
    PORTS)              ssSystemID="137";;   # PC Win9X
    PS)                 ssSystemID="57";;    # Sony Playstation
    PSP)                ssSystemID="61";;    # Sony PSP
    PSPMINIS)           ssSystemID="172";;   # Sony PSP Minis
    SATURN)             ssSystemID="22";;    # Sony PSP Minis
    SATELLAVIEW)        ssSystemID="107";;   # Satellaview
    SCUMMVM)            ssSystemID="123";;   # ScummVM
    SEGACD)             ssSystemID="20";;    # Sega CD
    SG1000)             ssSystemID="109";;   # Sega SG-1000
    ATARI7800)          ssSystemID="41";;    # Atari 7800
    SFC)                ssSystemID="4";;     # Super Nintendo (SNES)
    SFCMSU)             ssSystemID="4";;     # Super Nintendo (SNES) hacks
    SGB)                ssSystemID="127";;   # Super Game Boy
    SFX)                ssSystemID="105";;   # NEC PC Engine SuperGrafx
    SUFAMI)             ssSystemID="108";;   # Sufami Turbo
    WS)                 ssSystemID="207";;   # Watara Supervision
    WSC)                ssSystemID="207";;   # Watara Supervision
    SEGA32X)            ssSystemID="19";;    # Sega 32X
    SFX)                ssSystemID="19";;    # Sega 32X
    THOMSON)            ssSystemID="141";;   # Thomson
    TIC)                ssSystemID="222";;   # TIC-80
    UZEBOX)             ssSystemID="216";;   # Uzebox
    VB)                 ssSystemID="11";;    # Virtual Boy
    VECTREX)            ssSystemID="102";;   # Vectrex
    VIC20)              ssSystemID="73";;    # Commodore VIC-20
    VIDEOPAC)           ssSystemID="104";;   # Videopac
    VMU)                ssSystemID="23";;    # Dreamcast VMU (useless)
    WS)                 ssSystemID="45";;    # Bandai WonderSwan & Color
    X68000)             ssSystemID="79";;    # Sharp X68000
    X1)                 ssSystemID="220";;   # Sharp X1
    ZXEIGHTYONE)        ssSystemID="77";;    # Sinclair ZX-81
    ZXS)                ssSystemID="76";;    # Sinclair ZX Spectrum
    *)                  echo "Unknown platform"
  esac
}



saveMetadata=false
# clear

           
echo -e "\n******************************************************************************************"
echo -e "************************************** SCREENSCRAPER *************************************"
echo -e "******************************************************************************************\n\n"

#We check for existing credentials

ScraperConfigFile=/mnt/SDCARD/System/etc/scraper.json
if [ -f "$ScraperConfigFile" ]; then

    config=$(cat $ScraperConfigFile)

    MediaType=$(echo "$config" | jq -r '.Screenscraper_MediaType')

    SelectedRegion=$(echo "$config" | jq -r '.Screenscraper_Region')
    echo "Scraping Target: $CurrentSystem"
    echo "Media Type: $MediaType"
    echo "Current Region: $SelectedRegion"
    userSS=$(echo "$config" | jq -r '.screenscraper_username')
    passSS=$(echo "$config" | jq -r '.screenscraper_password')
    ScrapeInBackground=$(echo "$config" | jq -r '.ScrapeInBackground')
    u=$(echo -n KUZE433CLBLHSZCIOB2AU=== | base32 -d | base64 -d)
    p=$(echo -n KZEFMTCTIRBHMWJQN55GKSCRGFKGOPJ5BI====== | base32 -d | base64 -d)

    # public MediaType="box-2D"

    # Regions order management
    regionsDB="/mnt/SDCARD/System/usr/trimui/scripts/scraper/regions.db"
    RegionOrder=$(sqlite3 $regionsDB "SELECT ss_tree || ';' || ss_fallback FROM regions WHERE ss_nomcourt = '$SelectedRegion';")
    # we split the RegionOrder in each region variable (do not indent)
    IFS=';' read -r Region1 Region2 Region3 Region4 Region5 Region6 Region7 Region8 <<EOF
$RegionOrder
EOF
echo "Region search order: $RegionOrder"


    if [ "$userSS" = "null" ] || [ "$passSS" = "null" ] || [ "$userSS" = "" ] || [ "$passSS" = "" ]; then
        userStored="false"
    else
        userStored="true"
    fi
fi


if [ "$userStored" = "true" ]; then
    echo "screenscraper username: $userSS"
    echo -e "screenscraper password: xxxx (hidden)\n"
else
    echo -e "screenscraper account not configured.\n"
fi


if ! pgrep "text_viewer" >/dev/null  && [ "$ScrapeInBackground" = "false" ]; then
	NONE='\033[00m'
	RED='\033[01;31m'
	GREEN='\033[01;32m'
	YELLOW='\033[01;33m'
	PURPLE='\033[01;35m'
	CYAN='\033[01;36m'
	WHITE='\033[01;37m'
	BOLD='\033[1m'
	UNDERLINE='\033[4m'
	BLINK='\x1b[5m'
fi


# TODO : improve or remove this part (now in options)
if [ "$userStored" = "false" ] && [ "$ScrapeInBackground" = "false" ]; then
	Screenscraper_information
	break
fi



####################################################################################################################################

get_ssSystemID $CurrentSystem

mkdir -p "/mnt/SDCARD/Imgs/$CurrentSystem/" >/dev/null

#Roms loop

#if ! [ -z "$CurrentRom" ]; then
#    romfilter="-name  '*$CurrentRom*'"
#fi
if ! [ -z "$CurrentRom" ]; then
    # Escaping single quotes in CurrentRom
    CurrentRom_noapostrophe=${CurrentRom//\'/\\\'}
    romfilter="-name '*$CurrentRom_noapostrophe*'"
fi



# Build the find command with extensions from extlist

ExtList=$(jq -r '.extlist' "/mnt/SDCARD/Emus/$CurrentSystem/config.json")

if [ -z "$ExtList" ] || [ "$ExtList" = "null" ]; then
    find_filter="'!' -name '*.db' '!' -name '.gitkeep' '!' -name '*.launch'"
else
    ExtList=$(echo "$ExtList" | tr '|' ' ')
    find_filter=""
    first=1
    for ext in $ExtList; do
        if [ $first -eq 1 ]; then
            find_filter="-iname '*.$ext'"
            first=0
        else
            find_filter="$find_filter -o -iname '*.$ext'"
        fi
    done
    find_filter="'!' -name '*.db' '!' -name '.gitkeep' '!' -name '*.launch' -a \( $find_filter \)"
fi

# for debugging
# echo "Final find_filter: $find_filter"


# =================
#this is a trick to manage spaces from find command, do not move, indent or modify
IFS='
'
set -f
# =================

for file in $(eval "find /mnt/SDCARD/Roms/$CurrentSystem -maxdepth 2 -type f \
	! -name '.*' ! -name '*.xml' ! -name '*.miyoocmd' ! -name '*.cfg' ! -name '*.db' \
    ! -name '*.png' ! -name '*.state' ! -name '*.srm' \
    ! -path '*/Imgs/*' ! -path '*/.game_config/*' \
    $find_filter $romfilter"); do

        
    if pgrep "text_viewer" >/dev/null  && ! pgrep "getkey" >/dev/null && [ "$ScrapeInBackground" = "false" ]; then    # we're not in background scraping and B have been pressed, we display terminate the scraping task
        break
    fi	

    echo "-------------------------------------------------------------------------"
    gameIDSS=""
    url=""
    let romcount++

    # Cleaning up names
    romName=$(basename "$file")
    romNameNoExtension=${romName%.*}
    echo $romNameNoExtension

    romNameTrimmed="${romNameNoExtension/".nkit"/}"
    romNameTrimmed="${romNameTrimmed//"!"/}"
    romNameTrimmed="${romNameTrimmed//"&"/}"
    romNameTrimmed="${romNameTrimmed/"Disc "/}"
    romNameTrimmed="${romNameTrimmed/"Rev "/}"
    romNameTrimmed="$(echo "$romNameTrimmed" | sed -e 's/ ([^()]*)//g' -e 's/ \[[^]]*\]//g')"
    romNameTrimmed="${romNameTrimmed//" - "/"%20"}"
    romNameTrimmed="${romNameTrimmed/"-"/"%20"}"
    romNameTrimmed="${romNameTrimmed//" "/"%20"}"

    #echo $romNameTrimmed # for debugging

    if [ -f "/mnt/SDCARD/Imgs/$CurrentSystem/$romNameNoExtension.png" ]; then
        echo -e "${YELLOW}already Scraped !${NONE}"
        let Scrap_notrequired++

    else
        rom_size=$(stat -c%s "$file")
        url="https://www.screenscraper.fr/api2/jeuInfos.php?devid=${u%?}&devpassword=${p#??}&softname=crossmix&output=json&ssid=${userSS}&sspassword=${passSS}&sha1=&systemeid=${ssSystemID}&romtype=rom&romnom=${romNameTrimmed}.zip&romtaille=${rom_size}"
        search_on_screenscraper
        
        # Don't check art if we didn't get screenscraper game ID
        if ! [ "$gameIDSS" -eq "$gameIDSS" ] 2>/dev/null; then
            # Last chance : we search thanks to rom checksum
            MAX_FILE_SIZE_BYTES=104857600 #100MB

            if [ "$rom_size" -gt "$MAX_FILE_SIZE_BYTES" ]; then
                echo -e "${RED}Rom is too big to make a checksum.${NONE}"
                let Scrap_Fail++
                continue

            else
                echo -n "sha1 check..."
                checksum=$(sha1sum "$file" | awk '{ print $1 }')
                echo $checksum

                # !!! systemid must not be specified, it impacts the search by sha1 but not romtaille (must be > 2 however) or romnom. Most of other parameters than sha1 are useless for the request but helps to fill SS database
                url="https://www.screenscraper.fr/api2/jeuInfos.php?devid=${u%?}&devpassword=${p#??}&softname=crossmix&output=json&ssid=${userSS}&sspassword=${passSS}&sha1=${checksum}&systemeid=&romtype=rom&romnom=${romNameTrimmed}.zip&romtaille=${rom_size}"
                search_on_screenscraper
                if ! [ "$gameIDSS" -eq "$gameIDSS" ] 2>/dev/null; then
                    echo -e "${RED}Failed to get game ID${NONE}"
                    let Scrap_Fail++
                    continue
                fi

                RealgameName=$(echo "$api_result" | jq -r '.response.jeu.noms[0].text')
                echo Real name found : "$RealgameName"
            fi

        fi

        echo "gameID = $gameIDSS"

        api_result=$(echo $api_result | jq '.response.jeu.medias') # we keep only media section for faster search : 0.01s instead of 0.25s after that

        # for debugging :
        # echo -e "Region1: $Region1\nRegion2: $Region2\nRegion3: $Region3\nRegion4: $Region4\nRegion5: $Region5\nRegion6: $Region6\nRegion7: $Region7\nRegion8: $Region8\n$MediaType"
        # MediaType="box-2D"
        # region1="eu"
        # echo "$api_result" | jq --arg MediaType "$MediaType"  --arg Region1 "$region1"  --arg Region2 "$region2" 'map(select(.type == $MediaType)) | sort_by(if .region == $Region1 then 0 elif .region == $Region2 then 1 else 8 end)'
        # Old way:
        # MediaURL=$(echo "$api_result" | jq --arg MediaType "$MediaType" --arg Region "$region" '.response.jeu.medias[] | select(.type == $MediaType) | select(.region == $region) | .url' | head -n 1)
        # MediaURL=$(echo "$api_result" | jq --arg MediaType "$MediaType" --arg Region "$region" '.[] | select(.type == $MediaType) | select(.region == $region) | .url' | head -n 1)

        # this jq query will search all the images of type "MediaType" and will display it by order defined in RegionOrder
        MediaURL=$(echo "$api_result" | jq --arg MediaType "$MediaType" \
            --arg Region1 "$Region1" \
            --arg Region2 "$Region2" \
            --arg Region3 "$Region3" \
            --arg Region4 "$Region4" \
            --arg Region5 "$Region5" \
            --arg Region6 "$Region6" \
            --arg Region7 "$Region7" \
            --arg Region8 "$Region8" \
            'map(select(.type == $MediaType)) |
									  sort_by(if .region == $Region1 then 0
											elif .region == $Region2 then 1
											elif .region == $Region3 then 2
											elif .region == $Region4 then 3
											elif .region == $Region5 then 4
											elif .region == $Region6 then 5
											elif .region == $Region7 then 6
											elif .region == $Region8 then 7
											else 8 end) |
									.[0].url' | head -n 1)

        if [ -z "$MediaURL" ] || [ "$MediaURL" = "null" ]; then
            echo -e "${YELLOW}Game matches but no media found!${NONE}"
            let Scrap_Fail++
            continue
        fi

        # echo -e "Downloading Images for $romNameNoExtension \nScreenscraper ID : $gameIDSS \n url :$MediaURL\n\n"        # for debugging

        MediaURL=$(echo "$MediaURL" | sed 's/"$/\&maxwidth=400\&maxheight=580"/')

        # direct download triggers an error on Miyoo Mini Plus
        #wget --no-check-certificate "$MediaURL" -P "/mnt/SDCARD/Roms/$CurrentSystem/Imgs" -O "$romNameNoExtension.png"

        urlcmd=$(echo "wget  "$MediaURL" -O \"/mnt/SDCARD/Imgs/$CurrentSystem/$romNameNoExtension.png\"")
        echo $urlcmd >/tmp/rundl.sh
        sh /tmp/rundl.sh  >/dev/null 2>&1

        # /mnt/SDCARD/System/bin/wget "$MediaURL" -O "/mnt/SDCARD/Imgs/$CurrentSystem/$romNameNoExtension.png"

        if [ -f "/mnt/SDCARD/Imgs/$CurrentSystem/$romNameNoExtension.png" ]; then
            echo -e "${GREEN}Scraped!${NONE}"
            let Scrap_Success++
        else
            echo -e "${RED}Download failed.${NONE}"
            let Scrap_Fail++
        fi

     
        #pngscale "/mnt/SDCARD/Imgs/$CurrentSystem/$romNameNoExtension.png" "/mnt/SDCARD/Imgs/$CurrentSystem/$romNameNoExtension.png"

    fi

    #####################################################################################################################################
    #   saveMetadata=false

    #   if [ $saveMetadata == true ]; then
    #       mkdir -p /mnt/SDCARD/Roms/$CurrentSystem/info > /dev/null
    #
    #       if [ -f "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt" ]; then
    #           echo -e "${YELLOW}Metadata already Scraped !${NONE}"
    #       else
    #           genre_array=$( echo $api_result | jq -r '[foreach .response.jeu.genres[].noms[] as $item ([[],[]]; if $item.langue == "en" then $item.text else "" end)]'  )
    #           echo "" >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo game: $romNameNoExtension >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo file: $romName >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo developer: $( echo $api_result | jq -r  '.response.jeu.developpeur.text' ) >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo publisher: $( echo $api_result | jq -r  '.response.jeu.editeur.text'  ) >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo genre: $( echo $genre_array | jq '. - [""] | join(", ")' ) | sed 's/[\"]//g' >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo description: $( echo $api_result | jq -r  '.response.jeu.synopsis[0].text'  ) >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo release: $( echo $api_result | jq -r  '.response.jeu.dates[0].text'  ) >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo players: $( echo $api_result | jq -r  '.response.jeu.joueurs.text'  ) >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo rating: $( echo $api_result | jq -r  '.response.jeu.classifications[0].text'  ) >> "/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #           echo -e "Metadata saved to :\n/mnt/SDCARD/Roms/$CurrentSystem/info/$romNameNoExtension.txt"
    #       fi
    #   fi
    #####################################################################################################################################

    #TODO : get manual

done

echo -e "\n=========================================================================================="
echo -e "\n--------------------------"
echo "Total scanned roms   : $romcount"
echo "--------------------------"
echo "Successfully scraped : $Scrap_Success"
echo "Alread present       : $Scrap_notrequired"
echo "Failed or not found  : $Scrap_Fail"
echo -e "--------------------------\n"

echo -e "\n******************************************************************************************"
echo -e "***************************** Screenscraper scraping finished ****************************"
echo -e "******************************************************************************************\n\n"

sync
sleep 2
echo "Press MENU to exit."
echo ondemand >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
