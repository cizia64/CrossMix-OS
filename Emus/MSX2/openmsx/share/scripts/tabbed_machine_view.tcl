# This script visualizes with 'tabs' in the OSD the different running
# machines in openMSX.
# It only shows when there is more than one machine currently running.
# Because of that, it shouldn't be necessary to turn it off.
#
# Feel free to tune/improve the color scheme :)

# TODO:
# - needs events to know when a machine got deleted or created... now only
#   updates when there was a switch...
#   (Luckily, that is very often... but not enough!)

namespace eval tabbed_machine_view {

variable curtab_bgcolor 0x4040D0C0
variable curtab_text_color 0xFFFFFF
variable inactive_tab_bgcolor 0x202040A0
variable inactive_tab_text_color 0xA0A0A0
variable background_color 0x00000060
variable text_size 12
variable tab_margin 2
variable tab_main_spacing 3 ;# the width of the space between tab-row and main content
variable total_height 20
variable top_spacing 2


proc update {} {
	variable curtab_bgcolor
	variable curtab_text_color
	variable inactive_tab_bgcolor
	variable inactive_tab_text_color
	variable background_color
	variable tab_margin
	variable tab_main_spacing
	variable total_height
	variable top_spacing
	variable text_size

	osd destroy tabbed_machine_view

	if {[llength [list_machines]] > 1} {
		# init
		osd create rectangle tabbed_machine_view \
			-relw 1 \
			-h $total_height \
			-rgba $background_color \
			-x 0 \
			-y 0

		# create new ones
		set rel_width [expr {1.0 / [llength [list_machines]]}]
		set tab_count 0
		foreach machine [utils::get_ordered_machine_list] {
			if {$machine eq [activate_machine]} {
				set bg_color $curtab_bgcolor
				set text_color $curtab_text_color
				set display_text [utils::get_machine_display_name $machine]
			} else {
				set bg_color $inactive_tab_bgcolor
				set text_color $inactive_tab_text_color
				set display_text [format "%s (%s)" [utils::get_machine_display_name $machine] [utils::get_machine_time $machine]]
			}
			osd create rectangle tabbed_machine_view.${machine}_rect \
				-relx [expr {$tab_count * $rel_width}] \
				-x [expr { 2 * $tab_margin}] \
				-relw $rel_width \
				-w [expr {-2 * $tab_margin}] \
				-y $top_spacing \
				-h [expr {$total_height - $top_spacing + -$tab_main_spacing}] \
				-rgba $bg_color \
				-clip true
			osd create text tabbed_machine_view.${machine}_rect.text \
				-text $display_text \
				-size $text_size \
				-rgb $text_color \
				-x 1
			incr tab_count
		}
		# create the bottom 'line' for the visual tab effect
		osd create rectangle tabbed_machine_view.bottom_rect \
			-x 0 \
			-relw 1 \
			-rely 1 \
			-y [expr {-$tab_main_spacing}] \
			-h $tab_main_spacing \
			-rgba $curtab_bgcolor
	}
	after machine_switch [namespace code update]
}

proc on_mouse_click {} {
	set x 2; set y 2
	if {[osd exists tabbed_machine_view]} {
		catch {lassign [osd info "tabbed_machine_view" -mousecoord] x y}
		if {$x > 0 && 1 > $x && $y > 0 && 1 > $y} {
			set machine_index [expr int($x * [llength [list_machines]])]
			set machine [lindex [list_machines] $machine_index]
			activate_machine $machine
		}
	}

	after "mouse button1 up" [namespace code on_mouse_click]
}

after realtime 0.01 [namespace code update]
after "mouse button1 up" [namespace code on_mouse_click]

} ;# namespace tabbed_machine_view
