# This script is based on:
# openMSX metal gear overlay script 2014/12/07
# By Dunnius / Bifi / Vampier 

namespace eval metal_gear_overlay {

variable num_enemies 11
variable max_hp
variable punch_max_hp
variable currentfield
# the map feature is disabled here in code, because it isn't very useful yet
variable map_feature_enabled false
variable metal_gear_overlay_active false

variable enemy_names [list \
	"" "01" "Bridge Segment" "Ellen Screaming 'help me'" "Soldier - Pattern 1" \
	"Soldier - Pattern 2" "Camera" "Landmine" "Gas cloud" "Enemy - Tank" \
	"Soldier - (Alert)" "Soldier - Red (Alert)" "Tank Shell" \
	"Soldier - Shooting" "Soldier - Guard" "Roller" "Trap Floor" "Metal Gear" \
	"Enemy - Bulldozer" "Soldier - Truck" "Soldier - Flying" \
	"Soldier - Fly to the Switch" "Soldier - Flying (Alert)" "Unknown3" \
	"Soldier - Run to the Switch" "Guard Dog" "Mr. Arnold" "Basement Guard Dogs" \
	"Soldier - Guard to building 3" "Event - Dogs will appear" "Soldier - Pattern 3" \
	"Scorpion" "Big Boss" "Shoot Gunner" "Machine Gun Kid" "Laser fence" \
	"Fire Trooper" "Fire ball" "Hind-D" "Event - Incoming tank shells" \
	"Event - Guards will switch shifts" "Coward Duck" "Unknown8" \
	"Shoot Gunner - Bullet" "Power Switch" "Event - Snake Gets Captured" \
	"Event - Access to building 2" "Bullet 1" "Soldier - Stationary Guard" \
	"POW" "Ellen" "Grey Fox" "Dr. Petrovich" "Laser Camera" "36" "Fake Dr. Petrovich" \
	"Unknown9" "Soldier - Silencer Guards" "Unknown11" "Bullet 2" \
	"Machine Gun Kid - Bullet" "Bullet 3" "Tank - Bullet" "Boomerang" "Zzz" \
	"Unknown13" "Unknown14" "Unknown15" "44" "45" "46" "47" "48" "49" "4A" \
	"4B" "4C" "4D" "4E" "4F" "50" "51" "52" "53" "54" "55" "56" "57" "58" \
	"59" "5A" "5B" "5C" "5D" "5E" "5F" "60" "61" "62" "63" "64" "65" "66" ]

set_help_text toggle_metal_gear_overlay \
"Shows OSD widgets that help you play Metal Gear. Only useful if you
are actually running this game... If you are not, you may get a lot of weird
stuff on your screen :) It mostly shows Snake and enemy properties on screen
and events that will happen."

proc init {} {
	variable num_enemies
	variable max_hp
	variable punch_max_hp
	variable currentfield
	variable map_feature_enabled

	# Create OSD elements
	osd_widgets::msx_init metal_gear

	for {set i 0} {$i < $num_enemies} {incr i} {
		osd_widgets::create_power_bar metal_gear.powerbar$i 16 2 0xff0080b0 0x00000080 0xffffffC0
		osd_widgets::create_power_bar metal_gear.punchbar$i 16 2 0x0080ffb0 0x00000080 0xffffffC0
		set max_hp($i) 0
		set punch_max_hp($i) 0
	}

	osd_widgets::create_power_bar metal_gear.powerbarsnake 24 2 0x00ff00b0 0x00000080 0xffffffC0
	osd_widgets::create_power_bar metal_gear.boss  24 8 0x00ff00b0 0x00000080 0xffffffC0

	set currentfield 0
	
	if {$map_feature_enabled} {
		for {set y 0} {$y < 16} {incr y} {
			for {set x 0} {$x < 16} {incr x} {
				set field [expr {$x + ($y * 16)}]
				osd create rectangle metal_gear.field$field -x [expr {($x * 3) + 1}] -y [expr {($y * 3) + 1}] -relw 2 -relh 2 -rgba 0x0000ff80
			}
		}
	}

	# Start the overlay refresh
	update_overlay
}

proc update_impl {} {
	variable max_hp
	variable punch_max_hp
	variable num_enemies
	variable enemy_names
	variable currentfield
	variable map_feature_enabled

	# check for field change
	set newfield [peek 0xC130]
	if {$currentfield != $newfield} {
		set previousfield $currentfield
		set currentfield $newfield

		# clear out old HP values if field has changed
		for {set i 0} {$i < $num_enemies} {incr i} {
			set punch_max_hp($i) 0
			set max_hp($i) 0
		}
		if {$map_feature_enabled} {
			osd configure metal_gear.field$previousfield -rgba 0x00ff0080
			osd configure metal_gear.field$currentfield -rgba 0xffffff80
		}
	}

	for {set i 0; set addr 0xD000} {$i < $num_enemies} {incr i; incr addr 0x80} {
		set enemy_type [peek $addr]
		set enemy_hp [peek [expr {$addr + 0x0D}]]
		if {$enemy_type > 0 && $enemy_hp > 0} {
			set pos_x [peek [expr {$addr + 5}]]
			set pos_y [peek [expr {$addr + 3}]]

			if {$enemy_hp > $max_hp($i)} {
				set max_hp($i) $enemy_hp
			}
			set power [expr {1.00 * $enemy_hp / $max_hp($i)}]
			set text "HP: $enemy_hp $i [lindex $enemy_names $enemy_type] - #$enemy_type"
			osd_widgets::update_power_bar metal_gear.powerbar$i $pos_x $pos_y $power $text
								
			# only show the punch bar when the enemy can be punched
			set enemy_punch_hp [expr {3 - [peek [expr {$addr + 0x7A}]]}]
			if {$enemy_punch_hp > 0} {
				if {$enemy_punch_hp > $punch_max_hp($i)} {
					set punch_max_hp($i) $enemy_punch_hp
				}
				set punch_power [expr {1.00 * $enemy_punch_hp / $punch_max_hp($i)}]
				osd_widgets::update_power_bar metal_gear.punchbar$i $pos_x [expr {$pos_y + 5}] $punch_power ""
			} else {
				osd_widgets::update_power_bar metal_gear.punchbar$i -50 -50 0 ""
			}
		} else {
			osd_widgets::update_power_bar metal_gear.powerbar$i -50 -50 0 ""
			osd_widgets::update_power_bar metal_gear.punchbar$i -50 -50 0 ""
		}
        }

	# get stats for snake
	set snake_hp [peek 0xC131]
	set power [expr {$snake_hp / 48.0}]
	set poisoned [peek 0xC139]
	set pos_x [peek 0xC184]
	set pos_y [peek 0xc182]

	set text ""
	if {$poisoned == 1} {
		set power 0
		set text "POISONED "
	}
	append text "($pos_x,$pos_y)  HP: $snake_hp"

	osd_widgets::update_power_bar metal_gear.powerbarsnake [expr {$pos_x - 13}] [expr {$pos_y + 20}] $power $text
}

proc update_overlay {} {
	variable metal_gear_overlay_active
	if {!$metal_gear_overlay_active} return

	# check if not in demo or weapon/item screen
	set c012 [peek 0xC012]
	if {$c012 == 0x00 || $c012 == 0x47 || $c012 == 0x50 || [peek 0xC151] != 0} {
		osd configure metal_gear -y 999
	} else {
		osd configure metal_gear -y 0
		update_impl
	}
	after frame [namespace code update_overlay]
}

proc toggle_metal_gear_overlay {} {
	variable metal_gear_overlay_active
	set metal_gear_overlay_active [expr {!$metal_gear_overlay_active}]
	if {$metal_gear_overlay_active} {
		init
		set text "Metal Gear overlay activated!"
	} else {
		osd destroy metal_gear
		set text "Metal Gear overlay deactivated."
	}
	osd::display_message $text info
	return $text
}

namespace export toggle_metal_gear_overlay

};# namespace metal_gear_overlay

namespace import metal_gear_overlay::*
