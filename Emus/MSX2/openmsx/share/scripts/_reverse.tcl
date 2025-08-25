namespace eval reverse {

# Enable reverse if not yet enabled. As an optimization, also return
# reverse-status info (so that caller doesn't have to query it again).
proc auto_enable {} {
	set stat_dict [reverse status]
	if {[dict get $stat_dict status] eq "disabled"} {
		reverse start
	}
	return $stat_dict
}

set_help_text reverse_prev \
{Go back in time to the previous 'snapshot'.
A 'snapshot' is actually an internal implementation detail, but the\
important thing for this command is that the further back in the past,\
the less dense the snapshots are. So executing this command multiple times\
will take successively bigger steps in the past. Going back to a snapshot\
is also slightly faster than going back to an arbitrary point in time\
(let's say going back a fixed amount of time).
}
proc reverse_prev {{minimum 1} {maximum 15}} {
	set stats [auto_enable]
	set snapshots [dict get $stats snapshots]
	set num_snapshots [llength $snapshots]
	if {$num_snapshots == 0} return

	set current [dict get $stats current]
	set upperTarget [expr {$current - $minimum}]
	set lowerTarget [expr {$current - $maximum}]

	# search latest snapshot that is still before upperTarget
	set i [expr {$num_snapshots - 1}]
	while {([lindex $snapshots $i] > $upperTarget) && ($i > 0)} {
		incr i -1
	}
	# but don't go below lowerTarget
	set t [lindex $snapshots $i]
	if {$t < $lowerTarget} {set t $lowerTarget}

	reverse goto $t
}

set_help_text reverse_next \
{This is very much like 'reverse_prev', but instead it goes to the closest\
snapshot in the future (if possible).
}
proc reverse_next {{minimum 0} {maximum 15}} {
	set stats [auto_enable]
	set snapshots [dict get $stats snapshots]
	set num_snapshots [llength $snapshots]
	if {$num_snapshots == 0} return

	set current [dict get $stats current]
	set lowerTarget [expr {$current + $minimum}]
	set upperTarget [expr {$current + $maximum}]

	# search first snapshot that is after lowerTarget
	lappend snapshots [dict get $stats end]
	set i 0
	while {($i < $num_snapshots) && ([lindex $snapshots $i] < $lowerTarget)} {
		incr i
	}

	if {$i < $num_snapshots} {
		# but don't go above upperTarget
		set t [lindex $snapshots $i]
		if {$t > $upperTarget} {set t $upperTarget}
		reverse goto $t
	}
}

proc goto_time_delta {delta} {
	set t [expr {[dict get [reverse status] current] + $delta}]
	if {$t < 0} {set t 0}
	reverse goto $t
}

proc go_back_one_step {} {
	goto_time_delta [expr {-$::speed / 100.0}]
}

proc go_forward_one_step {} {
	goto_time_delta [expr { $::speed / 100.0}]
}


# reverse bookmarks

variable bookmarks [dict create]

proc create_bookmark_from_current_time {name} {
	variable bookmarks
	dict set bookmarks $name [machine_info time]
	# The next message is useful as part of a hotkey command for this
#	osd::display_message "Saved current time to bookmark '$name'"
	return "Created bookmark '$name' at [dict get $bookmarks $name]"
}

proc remove_bookmark {name} {
	variable bookmarks
	dict unset bookmarks $name
	return "Removed bookmark '$name'"
}

proc jump_to_bookmark {name} {
	variable bookmarks
	if {[dict exists $bookmarks $name]} {
		reverse goto [dict get $bookmarks $name]
		# The next message is useful as part of a hotkey command for
		# this
		#osd::display_message "Jumped to bookmark '$name'"
	} else {
		error "Bookmark '$name' not defined..."
	}
}

proc clear_bookmarks {} {
	variable bookmarks
	set bookmarks [dict create]
}

proc save_bookmarks {name} {
	variable bookmarks

	set directory [file normalize $::env(OPENMSX_USER_DATA)/../reverse_bookmarks]
	file mkdir $directory
	set fullname [file join $directory ${name}.rbm]

	if {[catch {
		set the_file [open $fullname {WRONLY TRUNC CREAT}]
		puts $the_file $bookmarks
		close $the_file
	} errorText]} {
		error "Failed to save to $fullname: $errorText"
	}
	return "Successfully saved bookmarks to $fullname"
}

proc load_bookmarks {name} {
	variable bookmarks

	set directory [file normalize $::env(OPENMSX_USER_DATA)/../reverse_bookmarks]
	set fullname [file join $directory ${name}.rbm]

	if {[catch {
		set the_file [open $fullname {RDONLY}]
		set bookmarks [read $the_file]
		close $the_file
	} errorText]} {
		error "Failed to load from $fullname: $errorText"
	}

	return "Successfully loaded $fullname"
}

proc list_bookmarks_files {} {
	set directory [file normalize $::env(OPENMSX_USER_DATA)/../reverse_bookmarks]
	set results [list]
	foreach f [lsort [glob -tails -directory $directory -type f -nocomplain *.rbm]] {
		lappend results [file rootname $f]
	}
	return $results
}

proc reverse_bookmarks {subcmd args} {
	switch -- $subcmd {
		"create" {create_bookmark_from_current_time {*}$args}
		"remove" {remove_bookmark  {*}$args}
		"goto"   {jump_to_bookmark {*}$args}
		"clear"  {clear_bookmarks}
		"load"   {load_bookmarks   {*}$args}
		"save"   {save_bookmarks   {*}$args}
		default  {error "Invalid subcommand: $subcmd"}
	}
}

set_help_proc reverse_bookmarks [namespace code reverse_bookmarks_help]

proc reverse_bookmarks_help {args} {
	switch -- [lindex $args 1] {
		"create"    {return {Create a bookmark at the current time with the given name.

Syntax: reverse_bookmarks create <name>
}}
		"remove" {return {Remove the bookmark with the given name.

Syntax: reverse_bookmarks remove <name>
}}
		"goto"   {return {Go to the bookmark with the given name.

Syntax: reverse_bookmarks goto <name>
}}
		"clear"  {return {Removes all bookmarks.

Syntax: reverse_bookmarks clear
}}
		"save"   {return {Save the current reverse bookmarks to a file.

Syntax: reverse_bookmarks save <filename>
}}
		"load"   {return {Load reverse bookmarks from file.

Syntax: reverse_bookmarks load <filename>
}}
		default {return {Control the reverse bookmarks functionality.

Syntax:  reverse_bookmarks <sub-command> [<arguments>]
Where sub-command is one of:
    create   Create a bookmark at the current time
    remove   Remove a previously created bookmark
    goto     Go to a previously created bookmark
    clear    Shortcut to remove all bookmarks
    save     Save current bookmarks to a file
    load     Load previously saved bookmarks

Use 'help reverse_bookmarks <sub-command>' to get more detailed help on a specific sub-command.
}}
	}
}

set_tabcompletion_proc reverse_bookmarks [namespace code reverse_bookmarks_tabcompletion]
proc reverse_bookmarks_tabcompletion {args} {
	variable bookmarks

	if {[llength $args] == 2} {
		return [list "create" "remove" "goto" "clear" "save" "load"]
	} elseif {[llength $args] == 3} {
		switch -- [lindex $args 1] {
			"remove" -
			"goto"  {return [dict keys $bookmarks]}
			"load"  -
			"save"  {return [list_bookmarks_files]}
			default {return [list]}
		}
	}
}

### auto save replays

trace add variable ::auto_save_replay "write" [namespace code auto_save_setting_changed]

variable old_auto_save_value $::auto_save_replay
variable auto_save_after_id 0

proc auto_save_setting_changed {name1 name2 op} {
	variable old_auto_save_value
	variable auto_save_after_id

	if {$::auto_save_replay != $old_auto_save_value} {
		set old_auto_save_value $::auto_save_replay

		if {$::auto_save_replay && $auto_save_after_id == 0 } {
			set stat_dict [reverse status]
			if {[dict get $stat_dict status] eq "disabled"} {
				error "Reverse is not enabled!"
			}
			auto_save_replay_loop
			puts "Enabled auto-save of replay to filename $::auto_save_replay_filename every $::auto_save_replay_interval seconds."
		} elseif {!$::auto_save_replay && $auto_save_after_id != 0 } {
			after cancel $auto_save_after_id
			set auto_save_after_id 0
			puts "Auto-save of replay disabled."
		}
	}
}

proc auto_save_replay_loop {} {
	variable auto_save_after_id

	if {$::auto_save_replay} {
		reverse savereplay -maxnofextrasnapshots 0 $::auto_save_replay_filename

		set auto_save_after_id [after realtime $::auto_save_replay_interval "reverse::auto_save_replay_loop"]
	}
}

namespace export reverse_prev
namespace export reverse_next
namespace export goto_time_delta
namespace export go_back_one_step
namespace export go_forward_one_step
namespace export reverse_bookmarks

} ;# namespace reverse


namespace eval reverse_widgets {

variable reverse_bar_update_interval 0.10

variable update_after_id 0
variable mouse_after_id 0
variable overlay_counter
variable prev_x 0
variable prev_y 0
variable overlayOffset
variable invisibleTime +inf ;# bar is invisble past this time, +inf means it's permanently visible

set_help_text toggle_reversebar \
{Enable/disable an on-screen reverse bar.
This will show the recorded 'reverse history' and the current position in\
this history. It is possible to click on this bar to immediately jump to a\
specific point in time. If the current position is at the end of the history\
(i.e. we're not replaying an existing history), this reverse bar will slowly\
fade out. You can make it reappear by moving the mouse over it.
}
proc toggle_reversebar {} {
	if {[osd exists reverse]} {
		disable_reversebar
	} else {
		enable_reversebar
	}
	return ""
}

proc enable_reversebar {{visible true}} {
	reverse::auto_enable

	if {[osd exists reverse]} {
		# osd already enabled
		return
	}

	# Reversebar
	set fade [expr {$visible ? 1.0 : 0.0}]
	osd create rectangle reverse \
		-scaled true -x 34 -y 1 -w 252 -h 8 \
		-rgba 0x00000080 -fadeCurrent $fade -fadeTarget $fade \
		-borderrgba 0xFFFFFFC0 -bordersize 1
	osd create rectangle reverse.int \
		-x 1 -y 1 -w 250 -h 6 -rgba 0x00000000 -clip true
	osd create rectangle reverse.int.bar \
		-relw 0 -relh 1 -z 3 -rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x55eeff80"
	osd create rectangle reverse.int.end \
		-relx 0 -x -1 -w 2 -relh 1      -z 3 -rgba 0xff8000c0
	osd create text      reverse.int.text \
		-x -10 -y 0 -relx 0.5 -size 5   -z 6 -rgba 0xffffffff

	# on mouse over hover box
	osd create rectangle reverse.mousetime \
		-relx 0.5 -rely 1 -relh 0.75 -z 4 \
		-rgba "0xffdd55e8 0xddbb33e8 0xccaa22e8 0xffdd55e8" \
		-bordersize 0.5 -borderrgba 0xffff4480
	osd create text reverse.mousetime.text \
		-size 5 -z 4 -rgba 0x000000ff

	update_reversebar

	variable mouse_after_id
	set mouse_after_id [after "mouse button1 down" [namespace code check_mouse]]

	trace add variable ::reverse::bookmarks "write" [namespace code update_bookmarks]
}

proc disable_reversebar {} {
	trace remove variable ::reverse::bookmarks "write" [namespace code update_bookmarks]
	variable update_after_id
	variable mouse_after_id
	after cancel $update_after_id
	after cancel $mouse_after_id
	osd destroy reverse
}

proc update_reversebar {} {
	catch {update_reversebar2}
	variable reverse_bar_update_interval
	variable update_after_id
	set update_after_id [after realtime $reverse_bar_update_interval [namespace code update_reversebar]]
}

proc update_reversebar2 {} {
	# Hack: Put the reverse bar at the bottom when the icons are at the top,
	#  otherwise at the top.
	#  It would be better to have a proper layout manager for the OSD stuff.
	if {[catch {set led_y [osd info osd_icons -y]}]} {
		set led_y 0
	}
	if {[catch {set led_w [osd info osd_icons -w]}]} {
		set led_w 0
	}
	osd configure reverse -y [expr {($led_y < 10) && ($led_w != 0) ? 231 : 1}]
	# Set time indicator position (depending on reverse bar position)
	variable overlayOffset [expr {($led_y > 16) ? 1.1 : -1.25}]


	set stats [reverse status]

	set x 2; set y 2
	catch {lassign [osd info "reverse.int" -mousecoord] x y}
	set mouseInside [expr {0 <= $x && $x <= 1 && 0 <= $y && $y <= 1}]

	variable invisibleTime
	set now [openmsx_info realtime]
	switch [dict get $stats status] {
		"disabled" {
			disable_reversebar
			return
		}
		"replaying" {
			osd configure reverse -fadeTarget 1.0 -fadeCurrent 1.0
			if {[reverse viewonlymode]} {
				set color "0x00aa44a0 0x22dd66a0 0x00cc55a0 0x55ffeea0"
			} else {
				set color "0x0044aaa0 0x2266dda0 0x0055cca0 0x55eeffa0"
			}
			osd configure reverse.int.bar -rgba $color
			set invisibleTime +inf
		}
		"enabled" {
			osd configure reverse.int.bar \
				-rgba "0xff4400a0 0xdd3300a0 0xbb2200a0 0xcccc11a0"
			if {$mouseInside || $::reversebar_fadeout_time == 0.0} {
				osd configure reverse -fadePeriod 0.5 -fadeTarget 1.0
				set invisibleTime +inf
			} else {
				osd configure reverse -fadePeriod $::reversebar_fadeout_time -fadeTarget 0.0
				if {$invisibleTime == +inf} {
					set invisibleTime [expr {$now + $::reversebar_fadeout_time}]
				}
			}
		}
	}
	if {$now > $invisibleTime} {
		# Optimization: reverse bar is completely faded out,
		#  don't bother keeping it up to date.
		return
	}

	set snapshots [dict get $stats snapshots]
	set begin     [dict get $stats begin]
	set end       [dict get $stats end]
	set current   [dict get $stats current]
	set totLenght  [expr {$end     - $begin}]
	set playLength [expr {$current - $begin}]
	set reciprocalLength [expr {($totLenght != 0) ? (1.0 / $totLenght) : 0}]
	set fraction [expr {$playLength * $reciprocalLength}]

	# Check if cursor moved compared to previous update,
	# if so reset counter (see below)
	variable overlay_counter
	variable prev_x
	variable prev_y
	if {$prev_x != $x || $prev_y != $y} {
		set overlay_counter 0
		set prev_x $x
		set prev_y $y
	}

	# Display mouse-over time jump-indicator
	# Hide when mouse hasn't moved for some time
	if {$mouseInside && $overlay_counter < 8} {
		variable overlayOffset
		set mousetext [utils::format_time_subseconds [expr {$x * $totLenght}]]
		osd configure reverse.mousetime.text -text $mousetext -relx 0.05
		set textsize [lindex [osd info reverse.mousetime.text -query-size] 0]
		osd configure reverse.mousetime -rely $overlayOffset -relx [expr {$x - 0.05}] -w [expr {1.1 * $textsize}]
		incr overlay_counter
	} else {
		osd configure reverse.mousetime -rely -100
	}

	# snapshots
	set count 0
	foreach snapshot $snapshots {
		set name reverse.int.tick$count
		if {![osd exists $name]} {
			# create new if it doesn't exist yet
			osd create rectangle $name -w 0.5 -relh 1 -rgba 0x444444ff -z 2
		}
		osd configure $name -relx [expr {($snapshot - $begin) * $reciprocalLength}]
		incr count
	}
	# destroy all snapshots with higher count number
	while {[osd destroy reverse.int.tick$count]} {
		incr count
	}

	# bookmarks
	set count 0
	dict for {bookmarkname bookmarkval} $::reverse::bookmarks {
		set name reverse.bookmark$count
		if {![osd exists $name]} {
			# create new if it doesn't exist yet
			osd create rectangle $name \
				-relx 0.5 -rely 1 -relh 0.75 -z 3 \
				-rgba "0xffdd55e8 0xddbb33e8 0xccaa22e8 0xffdd55e8" \
				-bordersize 0.5 -borderrgba 0xffff4480
			osd create text $name.text -relx -0.05 \
				-size 5 -z 3 -rgba 0x000000ff -text $bookmarkname
			set textsize [lindex [osd info $name.text -query-size] 0]
			osd configure $name -w [expr {1.1 * $textsize}]
		}
		osd configure $name -relx [expr {($bookmarkval - $begin) * $reciprocalLength}]
		incr count
	}

	# Round fraction to avoid excessive redraws caused by rounding errors
	set fraction [expr {round($fraction * 10000) / 10000.0}]
	osd configure reverse.int.bar -relw $fraction
	osd configure reverse.int.end -relx $fraction
	osd configure reverse.int.text \
		-text "[utils::format_time_subseconds $playLength] / [utils::format_time_subseconds $totLenght]"
}

proc check_mouse {} {
	catch {
		# click on reverse bar
		set x 2; set y 2
		catch {lassign [osd info "reverse.int" -mousecoord] x y}
		if {0 <= $x && $x <= 1 && 0 <= $y && $y <= 1} {
			set stats [reverse status]
			set begin [dict get $stats begin]
			set end   [dict get $stats end]
			reverse goto [expr {$begin + $x * ($end - $begin)}]
		}
		# click on bookmark
		set count 0
		dict for {bookmarkname bookmarkval} $::reverse::bookmarks {
			set name reverse.bookmark$count
			set x 2; set y 2
			catch {lassign [osd info $name -mousecoord] x y}
			if {0 <= $x && $x <= 1 && 0 <= $y && $y <= 1} {
				reverse::jump_to_bookmark $bookmarkname
			}
			incr count
		}
	}
	variable mouse_after_id
	set mouse_after_id [after "mouse button1 down" [namespace code check_mouse]]
}

proc update_bookmarks {name1 name2 op} {
	# remove all bookmarks to make sure the widget names start with 0
	# and have no 'holes' in their sequence. They will be recreated
	# when necessary in update_reversebar2

	set count 0
	while {[osd destroy reverse.bookmark$count]} {
		incr count
	}
	update_reversebar
}


namespace export toggle_reversebar
namespace export enable_reversebar
namespace export disable_reversebar

} ;# namespace reverse_widgets

namespace import reverse::*
namespace import reverse_widgets::*
