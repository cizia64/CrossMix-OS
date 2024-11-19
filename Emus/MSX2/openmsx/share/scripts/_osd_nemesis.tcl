set_help_text toggle_nemesis_1_shield \
{This command (de)activates some Nemesis 1 toys:
 - A shield around the players ship: enemy bullets will bounce off this shield.
 - Allow to move the ship with the mouse (click right mouse button to activate, click again to disable).
}

namespace eval osd_nemesis {

variable move_active false
variable after_frame_id
variable after_mouse_button_id

proc toggle_nemesis_1_shield {} {
	if {[osd exists "nemesis1"]} {
		disable_nemesis_1_shield
		osd::display_message "Nemesis 1 shield deactivated" info
	} else {
		enable_nemesis_1_shield
		osd::display_message "Nemesis 1 shield activated" info
	}
	return ""
}
namespace export toggle_nemesis_1_shield

proc disable_nemesis_1_shield {} {
	variable after_frame_id
	variable after_mouse_button_id

	osd destroy "nemesis1"
	after cancel $after_frame_id
	after cancel $after_mouse_button_id
}

proc enable_nemesis_1_shield {} {
	variable move_active
	variable after_frame_id
	variable after_mouse_button_id

	osd_widgets::msx_init "nemesis1"
	osd create rectangle "nemesis1.shield" \
		-fadeCurrent 0 -fadeTarget 0 -fadePeriod 2 \
		-image [data_file scripts/shield.png]

	set move_active false

	set after_frame_id [after time 0.1 osd_nemesis::after_frame]
	set after_mouse_button_id [after "mouse button1 down" osd_nemesis::after_mouse]
}

proc after_mouse {} {
	# click to capture and click again to release
	variable move_active
	variable after_mouse_button_id
	set move_active [expr {!$move_active}]
	set after_mouse_button_id [after "mouse button1 down" osd_nemesis::after_mouse]
}

proc after_frame {} {
	variable move_active
	variable after_frame_id

	osd_widgets::msx_update "nemesis1"

	if {$move_active} {
		# move vic viper to mouse position
		lassign [osd info "nemesis1" -mousecoord] x y
		catch { ;# when the cursor is hidden, -mousecoord won't give sane values
			poke 0xe206 [utils::clip 0 255 [expr {int($x)}]]
			poke 0xe204 [utils::clip 0 212 [expr {int($y)}]]
		}
	}

	# vic viper location
	set x [utils::clip 9 255 [peek 0xe206]]
	set y [utils::clip 0 192 [peek 0xe204]]
	osd configure "nemesis1.shield" -relx [expr {$x - 9}] -rely [expr {$y - 9}]

	for {set i 0} {$i < 32} {incr i} {
		# set base address
		set addr [expr {0xe300 + ($i * 0x20)}]

		# get enemy id
		set id [peek $addr]

		# enegry pod / flash pod / life pod / score pod /
		# endless score pod / explosion / end brain connections
		if {(17 <= $id) && ($id <= 26) && ($id != 20)} continue

		set a [peek [expr {$addr + 6}]]
		set b [peek [expr {$addr + 4}]]

		# Not in contact with shield? Then do nothing.
		if {((($a - $x + 6) ** 2) + (($b - $y + 7) ** 2)) >= 961} continue

		# ground turrets change into razor discs :)
		if {$id == 1 && $i < 16} {poke $addr 2}

		# homing ships and walkers
		if {$id == 4 || $id == 5} {poke $addr 21}

		# change color of sprite when in contact with shield
		# poke [expr {$addr + 13}] 15

		# Shield routine (hit front/back/top/bottom)
		set shieldstrength 2
		set dx [expr {($x > $a) ? -$shieldstrength : $shieldstrength}]
		set dy [expr {($y > $b) ? -$shieldstrength : $shieldstrength}]
		set xn [expr {$a + $dx}]
		set yn [expr {$b + $dy}]
		poke [expr {$addr +  6}] [utils::clip 0 255 $xn]
		poke [expr {$addr +  4}] [utils::clip 0 255 $yn]
		poke [expr {$addr +  8}] [expr {$dy & 255}]
		poke [expr {$addr + 10}] [expr {$dx & 255}]

		# make shield visible
		osd configure "nemesis1.shield" -fadeCurrent 0.5
	}
	set after_frame_id [after frame osd_nemesis::after_frame]
}

} ;# namespace osd_nemesis

namespace import osd_nemesis::*
