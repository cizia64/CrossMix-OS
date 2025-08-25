namespace eval tas {

### periodic refresh stuff

variable callback_list ""
variable callback_frame_id
variable callback_realtime_id

# TODO move to utils?
# Register the given callback to be executed
#  - (Once) when it is registered
#  - Every MSX frame
#  - Or at least 10 times per second (e.g. when MSX emulation is paused)
proc enable_periodic {callback} {
	variable callback_list
	variable callback_frame_id
	variable callback_realtime_id

	# on 1st callback activate the after-stuff
	if {[llength $callback_list] == 0} {
		set callback_frame_id    [after frame        [namespace code periodic_frame]]
		set callback_realtime_id [after realtime 0.1 [namespace code periodic_realtime]]
	}

	# add to list of registered callbacks
	lappend callback_list $callback

	# execute callback for the first time
	$callback
}

# Remove a previously registered callback. After this proc returns, the
# callback is guaranteed to not be called anymore. So it's (no longer)
# required to add a check in the callback proc.
proc disable_periodic {callback} {
	variable callback_list
	variable callback_frame_id
	variable callback_realtime_id

	# remove from registered callbacks
	set idx [lsearch -exact $callback_list $callback]
	if {$idx == -1} return
	set callback_list [lreplace $callback_list $idx $idx]

	# if the last callback was removed then deactivate after stuff
	if {[llength $callback_list] == 0} {
		after cancel $callback_frame_id
		after cancel $callback_realtime_id
	}
}

proc periodic_execute {} {
	variable callback_list
	foreach callback $callback_list {
		$callback
	}
}
proc periodic_frame {} {
	variable callback_frame_id
	variable callback_realtime_id

	periodic_execute

	# postpone 'after realtime' / reschedule 'after frame'
	after cancel $callback_realtime_id
	set callback_frame_id    [after frame        [namespace code periodic_frame]]
	set callback_realtime_id [after realtime 0.1 [namespace code periodic_realtime]]
}
proc periodic_realtime {} {
	variable callback_realtime_id

	periodic_execute

	# reschedule 'after realtime', no need to handle 'after frame'
	set callback_realtime_id [after realtime 0.1 [namespace code periodic_realtime]]
}


### frame counter ###

set_help_text toggle_frame_counter\
{Toggles display of a frame counter in the lower right corner.}

proc toggle_frame_counter {} {
	if {[osd exists framecount]} {
		disable_periodic framecount_update
		osd destroy framecount
		return ""
	}

	osd create rectangle framecount \
		-x 269 -y 227 -h 7 -w 42 -scaled true \
		-rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80" \
		-borderrgba 0x00000040 -bordersize 0.5
	osd create text framecount.text -x 3 -y 1 -size 4 -rgba 0xffffffff
	enable_periodic framecount_update
	return ""
}

proc framecount_update {} {
	# Heuristic: A 'ex (sp),ix' Z80 instruction takes 25 cycles. If we're
	# not more than 25 Z80 cycles past the start of a frame, then indicate
	# we're at the start of the frame. (But it could as well be the 2nd or
	# 3rd (short) instruction in the frame.)
	set inside [expr {([machine_info VDP_cycle_in_frame] < (6 * 25)) ? "" : "+"}]
	osd configure framecount.text -text "Frame: [machine_info VDP_frame_count]$inside"
}


### frame advance/reverse and helper procs for TAS mode key bindings ###

proc get_frame_duration {} {
	expr {(1368.0 * (([vdpreg 9] & 2) ? 313 : 262)) / (6 * 3579545)}
}
proc get_start_of_frame_time {} {
	expr {[machine_info time] - [machine_info VDP_cycle_in_frame] / (6.0 * 3579545)}
}

set_help_text prev_frame \
{Rewind to the (start of) the previous frame. Useful
to bind to a key in combination with next_frame. You can also
go back N frames if you add N as the optional argument.}
proc prev_frame {{count 1}} {
	set t [expr {[get_start_of_frame_time] - $count * [get_frame_duration]}]
	if {$t < 0} {set t 0}
	reverse goto $t
}

set_help_text next_frame \
{Emulates until the (start of) the next frame, then pause emulation.
Useful to bind to a key and emulate frame by frame. You can also
go over the next N frames if you add N as the optional argument.}
proc next_frame {{count 1}} {
	set t [expr {[get_start_of_frame_time] + $count * [get_frame_duration]}]
	after time [expr {$t - [machine_info time]}] "set ::pause on"
	set ::pause off
	return ""
}

set_help_text start_of_frame \
{Rewind to the start of the current frame.
See also prev_frame and next_frame.}
proc start_of_frame {} {
	prev_frame 0
}

set_help_text advance_frame \
{Emulate forward for the duration of one frame. The relative
timing position within the frame remains unchanged. You can also
advance N frames if you add N as the optional argument.}
proc advance_frame {{count 1}} {
	after time [expr {$count * [get_frame_duration]}] "set ::pause on"
	set ::pause off
	return ""
}

set_help_text reverse_frame \
{Emulate backward for the duration of one frame. The relative
timing position within the frame remains unchanged. You can also
reverse N frames if you add N as the optional argument.}
proc reverse_frame {{count 1}} {
	set t [expr {[machine_info time] - $count * [get_frame_duration]}]
	if {$t < 0} {set t 0}
	reverse goto $t
}

proc load_replay {name} {
	reverse loadreplay -goto savetime $name
	return ""
}


### Very basic replay slot selector ###

user_setting create string current_replay_slot "Name of the current replay slot." slot0

proc list_slots {} {
	set slots [list]
	for {set i 0} {$i <= 9} {incr i} {
		lappend slots "slot$i"
	}
	return $slots
}

proc menu_create_slot_menu {} {
	set items [list_slots]
	set menu_def \
		{ execute tas::set_slot
			font-size 8
			border-size 2
			width 100
			xpos 100
			ypos 100
			header { text "Select Replay Slot"
					font-size 10
					post-spacing 6 }}

	return [osd_menu::prepare_menu_list $items 10 $menu_def]
}

proc set_slot {item} {
	osd_menu::menu_close_all
	set ::current_replay_slot $item
}

proc open_select_slot_menu {} {
	osd_menu::do_menu_open [menu_create_slot_menu]
	osd_menu::select_menu_item $::current_replay_slot
	for {set i 0} {$i < [llength [tas::list_slots]]} {incr i} {
		bind -layer slot_menu "$i" "tas::set_slot [lindex [tas::list_slots] $i]; tas::unbind_number_keys"
	}
	activate_input_layer slot_menu
}

proc unbind_number_keys {} {
	deactivate_input_layer slot_menu
}

proc save_replay_slot {} {
	reverse savereplay $::current_replay_slot
}

proc load_replay_slot {} {
	load_replay $::current_replay_slot
}


### Show Cursor Keys / 'fire buttons and others' ###

variable keys

proc show_keys {} {
	variable keys

	# get joysticka values
	set joy [debug read joystickports 0]

	foreach key $keys {
		show_key_press [dict get $key name] [eval [dict get $key check_expr]]
	}
}

#move to other TCL script?
proc is_key_pressed {row bit} {
	expr {!([debug read keymatrix $row] & (1 << $bit))}
}

proc show_key_press {key state} {
	set keycol [expr {$state ? 0xff000080 : "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80"}]
	osd configure cursors.$key -rgba $keycol
}

proc create_key {name x y} {
	osd create rectangle cursors.$name -x $x -y $y -w 16 -h 7 \
	-rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80" \
	-bordersize 0.5 -borderrgba 0x00000040
	osd create text cursors.$name.text -x 2 -y 1 -text $name -size 4 -rgba 0xffffffff
}

# you can setup your own key definitions by loading a script which defines a proc like this:
#
# proc define_custom_keys {} {
#        variable tas::keys
#
#        set tas::keys {{
#                name up
#                x    20
#                y    2
#                check_expr {expr {([is_key_pressed 8 5] || !($joy &  1))}}
#        } {
#                name shift
#                x    186
#                y    8
#                check_expr {is_key_pressed 6 0}
#        }}
#}
#

proc toggle_cursors {} {
	variable keys

	if {[osd exists cursors]} {
		disable_periodic show_keys
		osd destroy cursors
	} else {
		osd create rectangle cursors -x 64 -y 219 -h 26 -w 204 -scaled true -rgba 0x00000000
		if {[info procs ::define_custom_keys] eq "::define_custom_keys"} {
			define_custom_keys
		} else {
			define_default_keys
		}
		foreach key $keys {
			create_key [dict get $key name] [dict get $key x] [dict get $key y]
		}
		enable_periodic show_keys
	}
}

proc define_default_keys {} {
	variable keys

	set keys {{
		name up
		x    20
		y    2
		check_expr {expr {([is_key_pressed 8 5] || !($joy &  1))}}
	} {
		name down
		x    20
		y    14
		check_expr {expr {([is_key_pressed 8 6] || !($joy &  2))}}
	} {
		name left
		x    2
		y    8
		check_expr {expr {([is_key_pressed 8 4] || !($joy &  4))}}
	} {
		name right
		x    38
		y    8
		check_expr {expr {([is_key_pressed 8 7] || !($joy &  8))}}
	} {
		name space
		x    60
		y    8
		check_expr {expr {([is_key_pressed 8 0] || !($joy & 16))}}
	} {
		name m
		x    78
		y    8
		check_expr {expr {([is_key_pressed 4 2] || !($joy & 32))}}
	} {
		name n
		x    96
		y    8
		check_expr {is_key_pressed 4 3}
	} {
		name z
		x    114
		y    8
		check_expr {is_key_pressed 5 7}
	} {
		name x
		x    132
		y    8
		check_expr {is_key_pressed 5 5}
	} {
		name graph
		x    150
		y    8
		check_expr {is_key_pressed 6 2}
	} {
		name ctrl
		x    168
		y    8
		check_expr {is_key_pressed 6 1}
	} {
		name shift
		x    186
		y    8
		check_expr {is_key_pressed 6 0}
	}}
}


### RAM Watch ###

# TODO:
# - be smarter with coordinates, by using negative ones
# - maybe put description on separate line to make window narrow again?

variable addr_watches [dict create]  ;# dict of RAM watches

# TODO move to utils?
proc dict_insert_sorted {dictname key value} {
	upvar $dictname d
	set i 0
	dict for {k v} $d {
		if {$key <= $k} {
			if {$key == $k} {
				dict set d $key $value
				return $d
			}
			break
		}
		incr i 2
	}
	set d [linsert $d $i $key $value]
}

proc ram_watch_add {addr_str args} {
	variable addr_watches

	set type_dict [dict create byte   {peek      2} b      {peek        2} \
	                           u8     {peek      2} s8     {peek_s8     2} \
	                           word   {peek16    4} w      {peek16      4} \
	                           u16    {peek16    4} s16    {peek_s16    4} \
	                           u16_LE {peek16    4} s16_LE {peek_s16    4} \
	                           u16_BE {peek16_BE 4} s16_BE {peek_s16_BE 4}]
	set format_dict [dict create dec "%d" hex "0x%0SX"]

	# sanitize input
	set addr [format 0x%04X $addr_str]
	if {($addr < 0) || ($addr > 0xffff)} {
		error "Address must be in range 0x0..0xffff, got: $addr_str"
	}

	set addr_already_watched [dict exists $addr_watches $addr]

	# defaults
	set desc "?"
	set type "byte"
	set format "hex"
	if {$addr_already_watched} {
		# start from the previously set values
		set desc   [dict get $addr_watches $addr -desc]
		set type   [dict get $addr_watches $addr -type]
		set format [dict get $addr_watches $addr -format]
	}

	while {[llength $args] > 0} {
		set option [lindex $args 0]
		switch -- $option {
			"-desc" {
				set desc [lindex $args 1]
				set args [lrange $args 2 end]
			}
			"-type" {
				set type [lindex $args 1]
				if {![dict exists $type_dict $type]} {
					error "Unsupported type: $type. Choose from: [dict keys $type_dict]"
				}
				set args [lrange $args 2 end]
			}
			"-format" {
				set format [lindex $args 1]
				if {![dict exists $format_dict $format]} {
					error "Unsupported format: $format. Choose from: [dict keys $format_dict]"
				}
				set args [lrange $args 2 end]
			}
			"default" {
				error "Invalid option: $option."
			}
		}
	}

	lassign [dict get $type_dict $type] peek_method num_hex_digits
	set fmtStr1 [dict get $format_dict $format]
	set fmtStr2 [string map [list S $num_hex_digits] $fmtStr1]
	set exprStr "set v \[$peek_method $addr\]; set r \"\[expr {(\$v < 0) ? \"-\" : \"\"}\]\[format $fmtStr2 \[expr {abs(\$v)}\]\]\"; set r"

	# add watch to watches
	set old_nof_watches [dict size $addr_watches]
	dict_insert_sorted addr_watches $addr [dict create -desc $desc -format $format -type $type exprStr $exprStr]

	# if OSD doesn't exist yet create it
	if {$old_nof_watches == 0} {
		ram_watch_init_widget
	}

	# (possibly) add one extra entry
	if {!$addr_already_watched} {
		ram_watch_add_to_widget $old_nof_watches
		ram_watch_update_widget_size
	}

	ram_watch_update_addresses
	if {$old_nof_watches == 0} {
		enable_periodic ram_watch_update_values
	}
	return ""
}

proc ram_watch_init_widget {} {
	osd create rectangle ram_watch \
		-x 0 -y 0 -h 240 -w 320 -scaled true -rgba 0x00000000
	osd create rectangle ram_watch.addr \
		-x 257 -y 1 -w 62 -h 221 \
		-rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80" \
		-borderrgba 0x00000040 -bordersize 0.5
	osd create text ram_watch.addr.title -text "RAM Watch" -x 2 -y 1 -size 4 -rgba 0xffffffff
}

proc ram_watch_update_widget_size {} {
	variable addr_watches
	set nr [dict size $addr_watches]
	osd configure ram_watch.addr -h [expr {8 + ($nr * 6)}]
}

proc ram_watch_add_to_widget {nr} {
	osd create rectangle ram_watch.addr.mem$nr \
		-x 2 -y [expr {8 + ($nr * 6)}] -h 5 -w 16 -rgba 0x40404080
	osd create text  ram_watch.addr.mem$nr.text \
		-size 4 -rgba 0xffffffff
	osd create rectangle ram_watch.addr.val$nr \
		-x 19 -y [expr {8 + ($nr * 6)}] -h 5 -w 17 -rgba 0x40404080
	osd create text  ram_watch.addr.val$nr.text \
		-size 4 -rgba 0xffffffff
	osd create rectangle ram_watch.addr.desc$nr \
		-x 37 -y [expr {8 + ($nr * 6)}] -h 5 -w 23 -rgba 0x40404080 -clip true
	osd create text  ram_watch.addr.desc$nr.text \
		-size 4 -rgba 0xffffffff
}

proc ram_watch_remove {addr_str} {
	variable addr_watches

	# sanitize input
	set addr [format 0x%04X $addr_str]

	# check watch exists
	if {![dict exists $addr_watches $addr]} {
		# not an error
		return ""
	}

	#remove address
	dict unset addr_watches $addr

	set i [dict size $addr_watches]

	#remove one OSD entry
	osd destroy ram_watch.addr.mem$i
	osd destroy ram_watch.addr.val$i
	osd destroy ram_watch.addr.desc$i

	#if all elements are gone don't display anything anymore.
	if {$i == 0} {
		disable_periodic ram_watch_update_values
		osd destroy ram_watch
	} else {
		ram_watch_update_addresses
		ram_watch_update_widget_size
	}
	return ""
}

proc ram_watch_clear {} {
	variable addr_watches
	set addr_watches [dict create]
	disable_periodic ram_watch_update_values
	osd destroy ram_watch
	return ""
}

proc ram_watch_update_addresses {} {
	variable addr_watches

	set i 0
	dict for {addr v} $addr_watches {
		osd configure ram_watch.addr.mem$i.text -text $addr
		osd configure ram_watch.addr.desc$i.text -text [dict get $v -desc]
		incr i
	}
}

proc ram_watch_update_values {} {
	variable addr_watches

	set i 0
	dict for {addr v} $addr_watches {
		set exprStr [dict get $v exprStr]
		osd configure ram_watch.addr.val$i.text -text [eval $exprStr]
		incr i
	}
}

proc ram_watch_save {name} {
	variable addr_watches

	# exprStr property doesn't need to be saved
	set filtered_watches [dict create]
	dict for {addr v} $addr_watches {
		dict set filtered_watches $addr [dict filter $v key -*]
	}

	set directory [file normalize $::env(OPENMSX_USER_DATA)/../ramwatches]
	file mkdir $directory
	set fullname [file join $directory ${name}.wch]

	if {[catch {
		set the_file [open $fullname {WRONLY TRUNC CREAT}]
		puts $the_file $filtered_watches
		close $the_file
	} errorText]} {
		error "Failed to save to $fullname: $errorText"
	}
	return "Successfully saved RAM watch to $fullname"
}

proc ram_watch_load {name} {
	variable addr_watches

	set directory [file normalize $::env(OPENMSX_USER_DATA)/../ramwatches]
	set fullname [file join $directory ${name}.wch]

	if {[catch {
		set the_file [open $fullname {RDONLY}]
		set new_addr_watches [read $the_file]
		close $the_file
	} errorText]} {
		error "Failed to load from $fullname: $errorText"
	}

	ram_watch_clear
	dict for {addr v} $new_addr_watches {
		ram_watch_add $addr {*}$v
	}
	return "Successfully loaded $fullname"
}

proc list_ram_watch_files {} {
	set directory [file normalize $::env(OPENMSX_USER_DATA)/../ramwatches]
	set results [list]
	foreach f [lsort [glob -tails -directory $directory -type f -nocomplain *.wch]] {
		lappend results [file rootname $f]
	}
	return $results
}

proc ram_watch {subcmd args} {
	switch -- $subcmd {
		"add"    {ram_watch_add    {*}$args}
		"remove" {ram_watch_remove {*}$args}
		"clear"  {ram_watch_clear  {*}$args}
		"load"   {ram_watch_load   {*}$args}
		"save"   {ram_watch_save   {*}$args}
		default  {error "Invalid subcommand: $subcmd"}
	}
}

set_help_proc ram_watch [namespace code ram_watch_help]
proc ram_watch_help {args} {
	switch -- [lindex $args 1] {
		"add"    {return {Add an address to the list of RAM watch addresses on the right side of the screen. The list will be updated in real time, whenever a value changes.

Syntax: ram_watch add <address> [<options>...]
Possible options are:
    -desc <description> describes the address
    -type <type>        datatype: byte, word, u8, s8, u16, s16, u16_BE, ...
    -format <format>    formatting: dec, hex
}}
		"remove" {return {Remove an address from the list of RAM watch addresses from the list of RAM watch addresses on the right side of the screen. When the last address is removed, the list will disappear automatically.

Syntax: ram_watch remove <address>
}}
		"clear"  {return {Removes all RAM watches.

Syntax: ram_watch clear
}}
		"save"   {return {Save the current list of RAM watches to a file.

Syntax: ram_watch save <filename>
}}
		"load"   {return {Load a list of RAM watches from file.

Syntax: ram_watch load <filename>
}}
		default {return {Control the RAM watch functionality.

Syntax:  ram_watch <sub-command> [<arguments>]
Where sub-command is one of:
    add      Add (or modify) a new RAM watch address
    remove   Remove a previously added address
    clear    Shortcut to remove all addresses
    save     Save current list of RAM watches to a file
    load     Load a previously saved list of RAM watches

Use 'help ram_watch <sub-command>' to get more detailed help on a specific sub-command.
}}
	}
}

set_tabcompletion_proc ram_watch [namespace code ram_watch_tabcompletion]
proc ram_watch_tabcompletion {args} {
	if {[llength $args] == 2} {
		return [list "add" "remove" "clear" "save" "load"]
	}
	switch -- [lindex $args 1] {
		"add"   {return [list -desc -type -format]}
		"load"  -
		"save"  {return [list_ram_watch_files]}
		default {return [list]}
	}
}

### Lag counter ###

variable lag_counter
variable lag_counter_wp
variable previous_frame_count 0
variable input_read_in_frame false

proc space_read {} {
	variable input_read_in_frame
	set input_read_in_frame true
}

proc toggle_lag_counter {} {
	variable lag_counter
	variable lag_counter_wp

	if {[osd exists lag_counter]} {
		osd destroy lag_counter
		debug remove_watchpoint $lag_counter_wp
		return ""
	}
	# we set it to -1, because the updater is always called at the start
	# and there the incr is present, so it will always incr. We compensate
	# for that by setting it to -1. See also on other places where we
	# force a call to the updater.
	set lag_counter -1

	set lag_counter_wp [debug set_watchpoint read_io 0xa9 {[expr [debug read ioports 0xaa] & 0x0f] == 0x08} {tas::space_read}]

	osd create rectangle lag_counter \
		-x 269 -y 220 -h 7 -w 42 -scaled true \
		-borderrgba 0x00000040 -bordersize 0.5
	osd create text lag_counter.text -x 3 -y 1 -size 4 -rgba 0xffffffff
	update_lag_counter ;# can't use enable_periodic
	return ""
}

proc update_lag_counter {} {
	update_lag_counter2
	after frame [namespace code update_lag_counter]
}

proc update_lag_counter2 {} {
	variable lag_counter
	variable previous_frame_count
	variable input_read_in_frame

	if {![osd exists lag_counter]} return

	set new_frame_count [machine_info VDP_frame_count]
	if {$new_frame_count == 1} {
		# reset lag counter if frame counter is reset (e.g. after reset, or loading replay)
		set lag_counter -1
	}
	# GFX9000 also triggers frame ends, so we should check if we
	# actually advanced a V99x8 frame here
	# Also, we check whether it was reset to force updating the display
	if { $previous_frame_count != $new_frame_count || $lag_counter == -1} {
		set previous_frame_count $new_frame_count

		set col [expr {!$input_read_in_frame ? 0xff000080 : "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80"}]
		osd configure lag_counter -rgba $col

		if {!$input_read_in_frame} {
			incr lag_counter
			osd configure lag_counter.text -text "Lag fr.: $lag_counter"
		} else {
			set input_read_in_frame false
		}
	}
}

proc reset_lag_counter {} {
	variable lag_counter
	set lag_counter -1
	update_lag_counter2
	return ""
}

### movie length display ###

set_help_text toggle_movie_length_display\
{Toggles display of the movie length in the upper right corner.}

proc toggle_movie_length_display {} {
	if {[osd exists movielength]} {
		disable_periodic movielength_update
		osd destroy movielength
		return ""
	}

	osd create rectangle movielength \
		-x 269 -y 234 -h 7 -w 42 -scaled true \
		-rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80" \
		-borderrgba 0x00000040 -bordersize 0.5
	osd create text movielength.text -x 3 -y 1 -size 4 -rgba 0xffffffff
	enable_periodic movielength_update
	return ""
}

proc movielength_update {} {
	osd configure movielength.text -text "Length: [utils::format_time_subseconds [dict get [reverse status] last_event]]"
}

namespace export toggle_frame_counter
namespace export prev_frame
namespace export next_frame
namespace export start_of_frame
namespace export advance_frame
namespace export reverse_frame
namespace export toggle_cursors
namespace export ram_watch
namespace export toggle_lag_counter
namespace export reset_lag_counter
namespace export toggle_movie_length_display
}

namespace import tas::*
