namespace eval mog_overlay {

variable num_enemies 16
variable num_rocks 8
variable mog_overlay_active false
variable mog_editor_active false
variable item_cache
variable tomb_cache
variable ladder_cache
variable wall_cache
variable demon_cache
variable ep
variable mouse1_pressed

# Demon summon spells
variable spell [list \
	"" "YOMAR" "ELOHIM" "HAHAKLA" "BARECHET" "HEOTYMEO" \
	"LEPHA" "NAWABRA" "ASCHER" "XYWOLEH" "HAMALECH"]
# Demon Max Power
variable demon_power [list -1 -1 24 40 64 112 72 56 64 80 80 248]
# Item names
variable items [list \
	"" "Arrow" "Ceramic Arrow" "Rolling Fire" "Fire" "Mine" \
	"Magnifying Glass" "Holy Water" "Cape" "Magical Rod" "World Map" \
	"Cross" "Great Key" "Necklace" "Crown" "Helm" "Oar" "Boots" "Doll" \
	"Robe" "Bell" "Halo" "Candle" "Armor" "Carpet" "Helmet" "Lamp" "Vase" \
	"Pendant" "Earrings" "Bracelet" "Ring" "Bible" "Harp" "Triangle" \
	"Trumpet Shell" "Pitcher" "Sabre" "Dagger" "Feather" "Bronze Shield" \
	"Bread and Water" "Salt" "Silver Shield" "Gold Shield" \
	"Quiver of Arrows" "Coins" "Keys"]

variable enemy_names [list \
	"" "Gorilla" "Twinkle" "HorBlob" "Gate" "Fire Snake" "06" "Ring Worm" \
	"08" "09" "Knight" "Water Strider" "Sparky" "Fish" "Bat" "Pacman" \
	"Insect" "Hedgehog" "Rockman" "Cloud Demon" "Mudman" "Ill" \
	"Bird Dragon" "Egg Bird" "Worm" "Butterfly" "Snake's Fire" "Fireball" \
	"1C" "1D" "1E" "Goblin" "20" "Crawler" "Pea Shooter" "Trapwall" "Swine" \
	"Bones" "Living Helmet" "Owl" "Ectoplasm" "29" "Poltergeist" "Wizard" \
	"Shoe 1" "Frost Demon" "Bamboo Shoot" "Frog Plant" "Seahorse Demon" \
	"31" "32" "Armor's Dart" "Bally" "35" "36" "Great Butterfly" "VerBlob" \
	"39" "3A" "Moai Head Projectile" "Trickster Ghost" "Star" \
	"Flocking Bird" "3F" "Cyclop's Ghost" "41" "Maner" "Gero" "44" "45" \
	"46" "47" "48" "Huge Bat" "4A" "4B" "Fuzzball" "4D" "4E" "4F" "50" "51" \
	"Middle Bat" "Mini Bat" "Bone" "Small Bone" "Small Fireball" "57" \
	"Crab's Breath" "Seed" "5A" "5B" "Spiral Ball " "5D" "5E" "5F" "Maner's Arm" "61" \
	"Gero's Tongue" "63" "Shoe 2" "Breath" "66" "Protectors"]

set_help_text toggle_mog_overlay \
"Shows OSD widgets that help you play The Maze of Galious. Only useful if you
are actually running this game... If you are not, you may get a lot of weird
stuff on your screen :) The script shows the Great Demon summon spells, ladders
which will disappear, walls which will grow, hitpoints of enemies, hidden
items, etc.\nSee also toggle_mog_editor."

set_help_text toggle_mog_editor \
"Gives you mouse bindings to fool around in The Maze of Galious. Only useful if
you are actually running this game... If you are not, you may get a lot of
weird stuff on your screen :) With this editor, you can draw walls with one
mouse button and put Popolon on your position of choice with the other. Needs
the MoG overlay to work, see toggle_mog_overlay."

#Init Overlays
proc init {} {
	variable num_enemies
	variable num_rocks
	variable label_color
	variable label_text_color
	variable item_cache
	variable tomb_cache
	variable ladder_cache
	variable wall_cache
	variable demon_cache
	variable max_ep

	osd_widgets::msx_init mog

	for {set i 0} {$i < $num_enemies} {incr i} {
		osd_widgets::create_power_bar mog.powerbar$i 14 2 0xff0000ff 0x00000080 0xffffffff
	}

	osd_widgets::create_power_bar mog.item 16 16 0x00000000 0xff770020 0xffffffff
	set item_cache 0

	osd create rectangle mog.tomb -rely 999 -w 16 -h 16 -rgba 0x00000080
	osd create text mog.tomb.text -x 1 -y 1 -size 5 -rgb 0xffffff
	set tomb_cache 0

	osd create rectangle mog.ladder -rely 999 -relw 16 -rgba 0xffffff80
	set ladder_cache 0

	osd create rectangle mog.wall -rely 999 -relw 8 -relh 24 -rgba 0x00ffff80
	set wall_cache 0

	osd create rectangle mog.wall2 -rely 999 -relw 32 -relh 24 -rgba 0x00000080
	osd create text mog.wall2.text -x 1 -y 1 -size 4 -rgb 0xffffff

	for {set i 0} {$i < $num_rocks} {incr i} {
		osd create rectangle mog.rock$i  -rely 999 -w 24 -h 4 -rgba 0x0000ff80
		osd create text mog.rock$i.text -x 0 -y 0 -size 4 -rgb 0xffffff
	}

	osd_widgets::create_power_bar mog.demon 48 4 0x2bdd2bff 0x00000080 0xffffffff
	set demon_cache 0

	# Enemy Power
	for {set i 0} {$i < $num_enemies} {incr i} {set max_ep($i) 0}
}

# Update the overlays
proc update_overlay {} {
	variable mog_overlay_active
	variable num_enemies
	variable num_rocks
	variable label_color
	variable label_text_color
	variable item_cache
	variable tomb_cache
	variable ladder_cache
	variable wall_cache
	variable demon_cache
	variable spell
	variable demon_power
	variable items
	variable enemy_names
	variable max_ep

	if {!$mog_overlay_active} return

	#see if not in demo
	if {[peek 0xe002] != 64} {osd configure mog -y 999} else {osd_widgets::msx_update mog}

	for {set i 0; set addr 0xe800} {$i < $num_enemies} {incr i; incr addr 0x20} {
		set enemy_type [peek $addr]
		set enemy_hp [peek [expr {$addr + 0x10}]]

		# If enemy's power is 0 set max power to 0
		if {$enemy_hp == 0 && $max_ep($i) > 0} {set max_ep($i) 0}

		if {$enemy_type > 0 && $enemy_hp > 0 && $enemy_hp < 200} {
			#Set Max Power Recorded for Enemy
			if {$max_ep($i) < $enemy_hp} {set max_ep($i) $enemy_hp}

			set pos_x [expr { 8 + [peek [expr {$addr + 7}]]}]
			set pos_y [expr {-6 + [peek [expr {$addr + 5}]]}]
			set power [expr {1.00 * $enemy_hp / $max_ep($i)}]
			set text [format "%s (%d): %d/%d" [lindex $enemy_names $enemy_type] $i $enemy_hp $max_ep($i)]
			osd_widgets::update_power_bar mog.powerbar$i $pos_x $pos_y $power $text
		} else {
			osd_widgets::hide_power_bar mog.powerbar$i
		}
	}

	set new_item [peek 0xe740]
	if {$new_item != $item_cache} {
		set item_cache $new_item
		if {$item_cache} {
			set height [expr {($item_cache < 7) ? 8 : 16}]
			osd configure mog.item -relh $height
			osd configure mog.item.text -text [lindex $items $item_cache]
			osd configure mog.item -relx [peek 0xe743] -rely [peek 0xe742]
		} else {
			osd configure mog.item -rely 999
		}
	}

	set new_tomb [peek 0xe678]
	if {$new_tomb != $tomb_cache} {
		set tomb_cache $new_tomb
		if {($tomb_cache > 0) && ($tomb_cache <= 10)} {
			osd configure mog.tomb.text -text "[lindex $spell $tomb_cache]"
			osd configure mog.tomb -relx [peek 0xe67a] -rely [peek 0xe679]
		} else {
			osd configure mog.tomb -rely 999
		}
	}

	#todo: see what the disappear trigger is (up, down, either)
	set new_ladder [expr {[peek 0xec00] | [peek 0xec07]}]
	if {$new_ladder != $ladder_cache} {
		set ladder_cache $new_ladder
		if {$ladder_cache != 0} {
			osd configure mog.ladder -relx [peek 0xec02] -rely [peek 0xec01] \
			                         -relh [expr {8 * ([peek 0xec03] & 31)}]
		} else {
			osd configure mog.ladder -rely 999
		}
	}

	set new_wall [peek 0xeaa0]
	if {$new_wall != $wall_cache} {
		set wall_cache $new_wall
		if {$wall_cache != 0} {
			osd configure mog.wall -relx [peek 0xeaa3] -rely [peek 0xeaa2]
		} else {
			osd configure mog.wall -rely 999
		}
	}

	if {[peek 0xea20] != 0} {
		set text [format "Wall (%02d)" [peek 0xea23]]
		osd configure mog.wall2 -relx [peek 0xea22] -rely [peek 0xea21]
		osd configure mog.wall2.text -text $text
	} else {
		osd configure mog.wall2 -rely 999
	}

	for {set i 0; set addr 0xec30} {$i < $num_rocks} {incr i; incr addr 8} {
		if {[peek $addr] > 0} {
			set pos_x [expr { 8 + [peek [expr {$addr + 3}]]}]
			set pos_y [expr {-6 + [peek [expr {$addr + 2}]]}]
			set rock_hp [peek [expr {$addr + 6}]]
			set text [format "Rock %d (%02d)" $i $rock_hp]
			osd configure mog.rock$i -relx $pos_x -rely $pos_y
			osd configure mog.rock$i.text -text $text
		} else {
			osd configure mog.rock$i -rely 999
		}
	}

	if {([peek 0xe0d2] != 0) && ([peek 0xe710] != 0)} {
		osd configure mog.demon -relx 112 -rely 26
		# let's not print text, it destroys a replay
		# print_mog_text 1 1 "Now Fighting [lindex $spell [expr {[peek 0xe041] - 1}]]"
		set new_demon [peek 0xe710]
		if {$new_demon != $demon_cache} {
			set demon_cache $new_demon
			set demon_max [lindex $demon_power [peek 0xe041]]
			if {$demon_max > 0} {
				set power [expr {$demon_cache * ([peek 0xe076] + 1.0) / $demon_max}]
				osd configure mog.demon.bar -relw $power
			}
		}
	} else {
		osd configure mog.demon -rely 999
	}

	after frame [namespace code update_overlay]
}

# better don't use this if you want to keep your replay OK
proc print_mog_text {x y text} {
	set text [string tolower $text]
	for {set i 0} {$i < [string length $text]} {incr i} {
		scan [string range $text $i $i] "%c" ascii
		incr ascii -86
		if {$ascii >= -38 && $ascii <= -29} {incr ascii 39}
		if {$ascii < 0} {set ascii 0}
		poke [expr {0xed80 + $x + $y * 32 + $i}] $ascii
	}
}

proc toggle_mog_overlay {} {
	variable mog_overlay_active
	variable mog_editor_active

	set mog_overlay_active [expr {!$mog_overlay_active}]

	if {$mog_overlay_active} {
		init
		update_overlay
		osd::display_message "MoG overlay activated" info
		return "MoG overlay activated!"
	} else {
		set retval ""
		if {$mog_editor_active} {
			set retval "[toggle_mog_editor]\n"
		}
		osd destroy mog
		osd::display_message "MoG overlay deactivated" info
		return "${retval}MoG overlay deactivated."
	}
}

# MoG editor
# Separated from MoG overlay, because the overlay is useful for TASing and the
# editor will ruin your replay

proc draw_block {} {
	osd_widgets::msx_update "mog"
	lassign [osd info "mog" -mousecoord] x y
	poke [expr {0xed80 + int($x / 8) + int(($y - 32) / 8) * 32}] 240
	if {$mog_overlay::mouse1_pressed} {after frame mog_overlay::draw_block}
}

proc put_popolon {} {
	osd_widgets::msx_update "mog"
	lassign [osd info "mog" -mousecoord] x y
	poke 0xe507 [utils::clip 0 255 [expr {int($x)}]]
	poke 0xe505 [utils::clip 0 212 [expr {int($y)}]]
}

proc toggle_mog_editor {} {
	variable mog_editor_active
	variable mog_overlay_active

	if {!$mog_editor_active && !$mog_overlay_active} {
		error "You need to have the MoG overlay active to use this editor!"
	}

	set mog_editor_active [expr {!$mog_editor_active}]

	if {$mog_editor_active} {
		bind -layer mog_editor "mouse button1 down" {
			set mog_overlay::mouse1_pressed true
			mog_overlay::draw_block
		}

		bind -layer mog_editor "mouse button1 up" {
			set mog_overlay::mouse1_pressed false
		}

		bind -layer mog_editor "mouse button3 down" {
			mog_overlay::put_popolon
		}
		activate_input_layer mog_editor
		return "MoG editor activated!"
	} else {
		deactivate_input_layer mog_editor
		return "MoG editor deactivated."
	}
	return ""
}

namespace export toggle_mog_overlay
namespace export toggle_mog_editor

};# namespace mog_overlay

namespace import mog_overlay::*
