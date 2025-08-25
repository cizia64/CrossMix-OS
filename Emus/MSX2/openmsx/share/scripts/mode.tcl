# TODO mode descriptions are not yet used in any way
# TODO tab completion for the mode setting, so we can remove the hardcoded mentioning of the existing modes

namespace eval mode {

## Mode switching infrastructure

variable modes_info
variable old_mode

proc register {name enter_proc leave_proc description} {
	variable modes_info
	dict set modes_info $name [dict create enter_proc $enter_proc \
	                                       leave_proc $leave_proc \
	                                       description $description]
}

proc mode_changed {name1 name2 op} {
	variable modes_info
	variable old_mode

	set new_mode $::mode
	if {![dict exists $modes_info $new_mode]} {
		# New mode doesn't exist, restore variable and give an error
		set ::mode $old_mode
		error "No such mode: $new_mode. Possible values are: [dict keys $modes_info]"
	}

	# Leave old mode
	eval [dict get $modes_info $old_mode leave_proc]

	# Enter new mode
	eval [dict get $modes_info $new_mode enter_proc]

	set old_mode $new_mode
}



## Define normal mode

proc enter_normal_mode {} {}
proc leave_normal_mode {} {}

register "normal" [namespace code enter_normal_mode] \
                  [namespace code leave_normal_mode] \
         "Mode that is most general purpose."



## Define tas mode

variable old_inputdelay
variable old_reversebar_fadeout_time

proc enter_tas_mode {} {

	variable old_inputdelay
	variable old_reversebar_fadeout_time

	# in tas mode, set inputdelay to 0
	set old_inputdelay $::inputdelay
	set ::inputdelay 0

	# in tas mode, do not fadeout reverse bar
	set old_reversebar_fadeout_time $::reversebar_fadeout_time
	set ::reversebar_fadeout_time 0

	if {![osd exists framecount]} {
		toggle_frame_counter
	}
	if {![osd exists lag_counter]} {
		toggle_lag_counter
	}
	if {![osd exists cursors]} {
		toggle_cursors
	}
	if {![osd exists movielength]} {
		toggle_movie_length_display
	}
	reverse_widgets::enable_reversebar false

	# load/select/save reverse slot
	# Note: this hides the MSX keys 'SELECT' and 'STOP'
	bind_default F6 tas::load_replay_slot
	bind_default F7 tas::open_select_slot_menu
	bind_default F8 tas::save_replay_slot

	# Set up frame advance/reverse
	bind_default END -repeat next_frame
	bind_default SCROLLLOCK -repeat prev_frame
}

proc leave_tas_mode {} {

	variable old_inputdelay
	variable old_reversebar_fadeout_time

	# restore inputdelay
	set ::inputdelay $old_inputdelay

	# restore reversebar_fadeout_time 
	set ::reversebar_fadeout_time $old_reversebar_fadeout_time

	if {[osd exists framecount]} {
		toggle_frame_counter
	}
	if {[osd exists lag_counter]} {
		toggle_lag_counter
	}
	if {[osd exists cursors]} {
		toggle_cursors
	}
	if {[osd exists movielength]} {
		toggle_movie_length_display
	}
	# Leave reverse enabled, including bar

	# Remove reverse slot stuff
	unbind_default F6
	unbind_default F7
	unbind_default F8

	# Remove frame advance/reverse
	unbind_default END
	unbind_default SCROLLLOCK
}

register "tas" [namespace code enter_tas_mode] \
               [namespace code leave_tas_mode] \
         "Mode for doing Tool Assisted Speedruns, with TAS widgets and easy ways to save replays."



# Create setting (uses info from registered modes above)

set help_text "This setting switches between different openMSX modes. A mode is a set of settings (mostly keybindings, but also OSD widgets that are activated) that are most suitable for a certain task. Currently these modes exist:"
foreach name [lsort [dict keys $modes_info]] {
	append help_text "\n  $name: [dict get $modes_info $name description]"
}

user_setting create string mode $help_text normal

trace add variable ::mode write [namespace code mode_changed]


## Enter initial mode

set old_mode $::mode
after realtime 0 {eval [dict get $mode::modes_info $::mode enter_proc]}

}
