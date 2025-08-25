namespace eval osd_keyboard {

# KNOWN ISSUES/TODO:
# * Shouldn't use the keymatrix command, but the 'type' command for all keys
#   that are not on the same position in the matrix for all machines
# * lots more? :P

variable is_dingux [string match dingux "[openmsx_info platform]"]

#init vars
variable mouse1_pressed false
variable key_pressed -1
variable key_selected -1
variable keys_held
variable row_starts

#init colors
variable key_color "0x999999c0 0xbbbbbbc0 0xddddddc0 0xffffffc0"
variable key_pressed_color "0x994400c0 0xbb5500c0 0xdd6600c0 0xff8800c0"
variable key_background_color 0x00000080
variable key_hold_color "0x009933f0 0x00bb44f0 0x00dd66f0 0x00ff88ff"
variable key_select_color "0x999933f0 0xbbbb44f0 0xdddd66f0 0xffff88f0"
variable key_edge_color 0xaaaaaaa0
variable key_edge_color_select 0xaaaa00a0
variable key_edge_color_hold 0x00aa44a0
variable key_edge_color_pressed 0xaa4444a0

# Keyboard layout constants.
variable key_height 16
variable key_hspace 2
variable key_vspace 2
variable board_hborder 4
variable board_vborder 4

proc toggle_osd_keyboard {} {
	if {[osd exists kb]} {
		disable_osd_keyboard
	} else {
		enable_osd_keyboard
	}
}

proc disable_osd_keyboard {} {
	osd destroy kb
	deactivate_input_layer osd_keyboard

	#reset keyboard matrix
	for {set i 0} {$i <= 8} {incr i} {
		keymatrixup $i 255
	}

	namespace eval ::osd_control {unset close}
}

proc enable_osd_keyboard {} {
	variable is_dingux
	variable mouse1_pressed false
	variable keys_held [list]
	variable row_starts [list]
	variable key_color
	variable key_background_color
	variable key_edge_color

	# first remove other OSD controlled widgets (like the osd menu)
	if {[info exists ::osd_control::close]} {
		eval $::osd_control::close
	}
	# and tell how to close this widget
	namespace eval ::osd_control {set close ::osd_keyboard::disable_osd_keyboard}

	#bind stuff
	bind -layer osd_keyboard "mouse button1 down"  {osd_keyboard::key_handler true}
	bind -layer osd_keyboard "mouse button1 up"    {osd_keyboard::key_handler false}

	bind -layer osd_keyboard "mouse button3 down"  {osd_keyboard::key_hold_toggle false}

	bind -layer osd_keyboard "OSDcontrol UP PRESS"     -repeat {osd_keyboard::selection_row -1}
	bind -layer osd_keyboard "OSDcontrol DOWN PRESS"   -repeat {osd_keyboard::selection_row +1}
	bind -layer osd_keyboard "OSDcontrol LEFT PRESS"   -repeat {osd_keyboard::selection_col -1}
	bind -layer osd_keyboard "OSDcontrol RIGHT PRESS"  -repeat {osd_keyboard::selection_col +1}
	if {$is_dingux} {
		bind -layer osd_keyboard "keyb LCTRL,PRESS"   {osd_keyboard::selection_press  }
		bind -layer osd_keyboard "keyb LCTRL,RELEASE" {osd_keyboard::selection_release}
		bind -layer osd_keyboard "keyb LALT"          {osd_keyboard::key_hold_toggle true }
	} else {
		bind -layer osd_keyboard "OSDcontrol B PRESS"    {osd_keyboard::selection_press  }
		bind -layer osd_keyboard "OSDcontrol B RELEASE"  {osd_keyboard::selection_release}
		bind -layer osd_keyboard "OSDcontrol A PRESS"          {osd_keyboard::key_hold_toggle true }
	}
	activate_input_layer osd_keyboard -blocking

	#Define Keyboard (how do we handle the shift/ctrl/graph command?)
	set key_basewidth 18
	set rows {
		"F1*26|F2*26|F3*26|F4*26|F5*26|null*8|Select*26|Stop*26|null*8|Home*26|Ins*26|Del*26" \
		 "Esc|1|2|3|4|5|6|7|8|9|0|-|=|\\|BS" \
		 "Tab*28|Q|W|E|R|T|Y|U|I|O|P|\[|]|Return*28" \
		 "Ctrl*32|A|S|D|F|G|H|J|K|L|;|'|`|<--*24" \
		 "Shift*40|Z|X|C|V|B|N|M|,|.|/|Acc|Shift*36" \
		 "null*40|Cap|Grp|Space*158|Cod"
	}

	# Keyboard layout constants.
	variable key_height
	variable key_hspace
	variable key_vspace
	variable board_hborder
	variable board_vborder

	# Create widgets.
	set board_width \
		[expr {15 * $key_basewidth + 14 * $key_hspace + 2 * $board_hborder}]
	set board_height \
		[expr {6 * $key_height + 5 * $key_vspace + 2 * $board_vborder}]
	osd create rectangle kb \
		-x [expr {(320 - $board_width) / 2}] \
		-y 4 \
		-w $board_width \
		-h $board_height -scaled true -rgba $key_background_color
	set keycount 0
	for {set y 0} {$y <= [llength $rows]} {incr y} {
		set y_base [expr {$board_vborder + $y * ($key_height + $key_vspace)}]
		lappend row_starts $keycount
		set x $board_hborder
		foreach {keys} [split [lindex $rows $y] "|"] {
			lassign [split $keys "*"] key_text key_width
			if {$key_width < 1} {set key_width $key_basewidth}
			if {$key_text ne "null"} {
				set key_y $y_base
				set key_h $key_height
				set bordersize 1
				if {$key_text eq "Return"} {
					set bordersize 0
				} elseif {$key_text eq "<--"} {
					set bordersize 0
					incr key_y -$key_vspace
					incr key_h  $key_vspace
				}
				osd create rectangle kb.$keycount \
					-x $x -y $key_y \
					-w $key_width -h $key_h \
					-rgba $key_color \
					-bordersize $bordersize \
					-borderrgba $key_edge_color
				osd create text kb.$keycount.text \
					-x 1.1 \
					-y 0.1 \
					-text $key_text \
					-size 8
				incr keycount
			}
			set x [expr {$x + $key_width + $key_hspace}]
		}
	}

	variable key_selected
	if {$key_selected == -1} {
		# Select the key in the middle of the keyboard.
		key_select [key_at_coord \
			[expr {$board_width / 2}] \
			[expr {$board_vborder + 3.5 * ($key_height + $key_vspace)}]]
	} else {
		update_key_color $key_selected
	}

	return ""
}

proc selection_row {delta} {
	variable row_starts
	variable key_selected

	# Note: Delta as bias makes sure that if a key is exactly in the middle
	#       above/below two other keys, an up/down or down/up sequence will
	#       end on the same key it started on.
	set x [expr {\
		[osd info kb.$key_selected -x] + [osd info kb.$key_selected -w] / 2 \
		+ $delta}]
	set num_rows [expr {[llength $row_starts] - 1}]
	set row [row_for_key $key_selected]
	while {1} {
		# Determine new row.
		incr row $delta
		if {$row < 0} {
			set row [expr {$num_rows - 1}]
		} elseif {$row >= $num_rows} {
			set row 0
		}

		# Get key at new coordinates.
		set first_key [lindex $row_starts $row]
		set y [expr {\
			[osd info kb.$first_key -y] + [osd info kb.$first_key -h] / 2}]
		set new_selection [key_at_coord $x $y]
		if {$new_selection >= 0} {
			break
		}
	}

	key_select $new_selection
}

proc selection_col {delta} {
	variable row_starts
	variable key_selected

	# Figure out first and last key of current row.
	set row [row_for_key $key_selected]
	set row_start [lindex $row_starts $row]
	set row_end [lindex $row_starts [expr {$row + 1}]]

	# Move left or right.
	set new_selection [expr {$key_selected + $delta}]
	if {$new_selection < $row_start} {
		set new_selection [expr {$row_end - 1}]
	} elseif {$new_selection >= $row_end} {
		set new_selection $row_start
	}

	key_select $new_selection
}

proc selection_press {} {
	variable key_selected
	key_press $key_selected
}

proc selection_release {} {
	key_release
}

proc key_press {key_id} {
	variable key_pressed

	set key_pressed $key_id
	key_matrix $key_id down
	update_key_color $key_id
}

proc key_release {} {
	variable key_pressed
	variable keys_held

	if {$key_pressed == -1} {
		return
	}

	set key_id $key_pressed
	set key_pressed -1
	set index [lsearch -exact $keys_held $key_id]
	if {$index != -1} {
		set keys_held [lreplace $keys_held $index $index]
	}
	key_matrix $key_id up
	update_key_color $key_id
}

proc key_select {key_id} {
	variable key_selected

	set old_selected $key_selected
	set key_selected $key_id
	update_key_color $key_selected
	update_key_color $old_selected
}

proc row_for_key {key_id} {
	variable row_starts
	for {set row 0} {$row < [llength $row_starts] - 1} {incr row} {
		set row_start [lindex $row_starts $row]
		set row_end [lindex $row_starts [expr {$row + 1}]]
		if {$row_start <= $key_id && $key_id < $row_end} {
			return $row
		}
	}
	return -1
}

proc update_key_color {key_id} {
	variable key_selected
	variable key_pressed
	variable keys_held
	variable key_color
	variable key_select_color
	variable key_pressed_color
	variable key_hold_color
	variable key_edge_color
	variable key_edge_color_select
	variable key_edge_color_hold
	variable key_edge_color_pressed

	if {$key_id < 0} {
		return
	} elseif {$key_id == $key_pressed} {
		set color $key_pressed_color
		set edge_color $key_edge_color_pressed
	} elseif {$key_id == $key_selected} {
		set color $key_select_color
		set edge_color $key_edge_color_select
	} elseif {$key_id in $keys_held} {
		set color $key_hold_color
		set edge_color $key_edge_color_hold
	} else {
		set color $key_color
		set edge_color $key_edge_color
	}
	osd configure kb.$key_id -rgba $color -borderrgba $edge_color
}

proc key_at_coord {x y} {
	variable key_hspace
	variable key_height
	variable key_vspace
	variable board_vborder
	variable row_starts

	set row [expr {int(floor( \
		($y - $board_vborder + $key_vspace / 2) / ($key_height + $key_vspace) \
		))}]
	if {$row >= 0 && $row < [llength $row_starts] - 1} {
		set row_start [lindex $row_starts $row]
		set row_end [lindex $row_starts [expr {$row + 1}]]
		for {set key_id $row_start} {$key_id < $row_end} {incr key_id} {
			set relx [expr {$x - [osd info kb.$key_id -x] + $key_hspace / 2}]
			if {$relx >= 0 && $relx < [osd info kb.$key_id -w] + $key_hspace} {
				return $key_id
			}
		}
	}
	return -1
}

proc key_at_mouse {} {
	lassign [osd info kb -mousecoord] x y
	key_at_coord [expr {$x * [osd info kb -w]}] \
	             [expr {$y * [osd info kb -h]}]
}

proc key_hold_toggle {at_selection} {
	variable keys_held
	variable key_selected

	if {$at_selection} {
		set key_id $key_selected
	} else {
		set key_id [key_at_mouse]
	}
	if {$key_id >= 0} {
		set index [lsearch -exact $keys_held $key_id]
		if {$index == -1} {
			key_matrix $key_id down
			lappend keys_held $key_id
		} else {
			key_matrix $key_id up
			set keys_held [lreplace $keys_held $index $index]
		}
		update_key_color $key_id
	}
}

proc key_handler {mouse_state} {
	if {$mouse_state} {
		set key_id [key_at_mouse]
		if {$key_id >= 0} {
			key_press $key_id
			key_select $key_id
		}
	} else {
		key_release
	}
}

proc key_matrix {keynum state} {
	set key [string trim "[osd info kb.$keynum.text -text]"]

	set km keymatrix$state

	#info from http://map.grauw.nl/articles/keymatrix.php (thanks Grauw)

	switch -- $key {
		"0"      {$km 0 1}
		"1"      {$km 0 2}
		"2"      {$km 0 4}
		"3"      {$km 0 8}
		"4"      {$km 0 16}
		"5"      {$km 0 32}
		"6"      {$km 0 64}
		"7"      {$km 0 128}

		"8"      {$km 1 1}
		"9"      {$km 1 2}
		"-"      {$km 1 4}
		"="      {$km 1 8}
		"\\"     {$km 1 16}
		"\["     {$km 1 32}
		"\]"     {$km 1 64}
		";"      {$km 1 128}

		"'"      {$km 2 1}
		"`"      {$km 2 2}
		","      {$km 2 4}
		"."      {$km 2 8}
		"/"      {$km 2 16}
		"Acc"    {$km 2 32}
		"A"      {$km 2 64}
		"B"      {$km 2 128}

		"C"      {$km 3 1}
		"D"      {$km 3 2}
		"E"      {$km 3 4}
		"F"      {$km 3 8}
		"G"      {$km 3 16}
		"H"      {$km 3 32}
		"I"      {$km 3 64}
		"J"      {$km 3 128}

		"K"      {$km 4 1}
		"L"      {$km 4 2}
		"M"      {$km 4 4}
		"N"      {$km 4 8}
		"O"      {$km 4 16}
		"P"      {$km 4 32}
		"Q"      {$km 4 64}
		"R"      {$km 4 128}

		"S"      {$km 5 1}
		"T"      {$km 5 2}
		"U"      {$km 5 4}
		"V"      {$km 5 8}
		"W"      {$km 5 16}
		"X"      {$km 5 32}
		"Y"      {$km 5 64}
		"Z"      {$km 5 128}

		"Shift"  {$km 6 1}
		"Ctrl"   {$km 6 2}
		"Grp"    {$km 6 4}
		"Cap"    {$km 6 8}
		"Cod"    {$km 6 16}
		"F1"     {$km 6 32}
		"F2"     {$km 6 64}
		"F3"     {$km 6 128}

		"F4"     {$km 7 1}
		"F5"     {$km 7 2}
		"Esc"    {$km 7 4}
		"Tab"    {$km 7 8}
		"Stop"   {$km 7 16}
		"BS"     {$km 7 32}
		"Select" {$km 7 64}
		"Return" {$km 7 128}
		"<--"    {$km 7 128}

		"Space"  {$km 8 1}
		"Home"   {$km 8 2}
		"Ins"    {$km 8 4}
		"Del"    {$km 8 8}
	}

	#cursor keys etc (not implemented... should we?)
	#numeric keyboard?
}

namespace export toggle_osd_keyboard

};# namespace osd_keyboard

namespace import osd_keyboard::*
