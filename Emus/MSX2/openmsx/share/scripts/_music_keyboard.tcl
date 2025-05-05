# TODO:
# - optimize by precalcing the notes for all reg values
# - make a better visualisation if many channels are available (grouping?)

set_help_text toggle_music_keyboard \
{Puts a music keyboard on the On-Screen-Display for each channel and each
supported sound chip. It is not very practical yet if you have many
sound chips in your currently running MSX. The redder a key on the
keyboard is, the louder the note is played. Use the command again to
remove it. Note: it cannot handle run-time insertion/removal of sound
devices. It can handle changing of machines, though. Not all chips are
supported yet and some channels give not so useful note output (but
still it is nice to see something happening).
Note that displaying these keyboard may cause quite some CPU load!}

namespace eval music_keyboard {

# some useful constants
variable note_strings [list "C" "C#" "D" "D#" "E" "F" "F#" "G" "G#" "A" "A#" "B"]
# we define these outside the proc to gain some speed (they are precalculated)
variable loga [expr {log(2 ** (1 / 12.0))}]
variable r3 [expr {log(440.0) / $loga - 57}]

variable keyb_dict
variable note_key_color
variable num_notes
variable machine_switch_trigger_id 0
variable frame_trigger_id 0

proc freq_to_note {freq} {
	variable loga
	variable r3
	expr {($freq < 16) ? -1 : (log($freq) / $loga - $r3)}
}

proc keyboard_init {} {
	variable num_notes
	variable note_strings
	variable note_key_color
	variable keyb_dict
	variable machine_switch_trigger_id

	foreach soundchip [machine_info sounddevice] {
		set channel_count [soundchip_utils::get_num_channels $soundchip]
		for {set channel 0} {$channel < $channel_count} {incr channel} {
			set freq_expr [soundchip_utils::get_frequency_expr $soundchip $channel]
			# skip devices/channels which don't have freq expressions (not implemented yet)
			if {$freq_expr eq "x"} continue
			dict set keyb_dict $soundchip $channel [dict create \
				freq_expr $freq_expr \
				vol_expr  [soundchip_utils::get_volume_expr    $soundchip $channel] \
				prev_note 0]
		}
	}

	# and now create the visualisation (keyboards)
	set num_octaves 9
	set num_notes [expr {$num_octaves * 12}]
	set key_width 3
	set border 1
	set yborder 1
	set step_white [expr {$key_width + $border}] ;# total width of white keys
	set keyboard_height 8
	set white_key_height [expr {$keyboard_height - $yborder}]

	osd create rectangle music_keyboard -scaled true
	set channel_count 0
	dict for {soundchip chip_dict} $keyb_dict {
		dict for {channel chan_dict} $chip_dict {
			osd create rectangle music_keyboard.chip${soundchip}ch${channel} \
				-y [expr {$channel_count * $keyboard_height}] \
				-w [expr {($num_octaves * 7) * $step_white + $border}] \
				-h $keyboard_height \
				-rgba 0x101010A0
			set nof_blacks 0
			for {set note 0} {$note < $num_notes} {incr note} {
				set z -1
				set xcor 0
				if {[string range [lindex $note_strings [expr {$note % 12}]] end end] eq "#"} {
					# black key
					dict set note_key_color $note 0x000000
					set h [expr {round($white_key_height * 0.7)}]
					set xcor [expr {($key_width + 1) / 2}]
					incr nof_blacks
				} else {
					# white key
					set h $white_key_height
					dict set note_key_color $note 0xFFFFFF
					set z -2
				}
				osd create rectangle music_keyboard.chip${soundchip}ch${channel}.key${note} \
					-x [expr {($note - $nof_blacks) * $step_white + $border + $xcor}] \
					-y 0 -z $z \
					-w $key_width -h $h \
					-rgb [dict get $note_key_color $note]
			}

			set next_to_kbd_x [expr {($num_notes - $nof_blacks) * $step_white + $border}]

			osd create rectangle music_keyboard.ch${channel}chip${soundchip}infofield \
				-x $next_to_kbd_x -y [expr {$channel_count * $keyboard_height}] \
				-w [expr {320 - $next_to_kbd_x}] -h $keyboard_height \
				-rgba 0x000000A0
			osd create text music_keyboard.ch${channel}chip${soundchip}infofield.notetext \
				-rgb 0xFFFFFF -size [expr {round($keyboard_height * 0.75)}]
			osd create text music_keyboard.ch${channel}chip${soundchip}infofield.chlabel \
				-rgb 0x1F1FFF -size [expr {round($keyboard_height * 0.75)}] \
				-x 10 -text "[expr {$channel + 1}] ($soundchip)"
			incr channel_count
		}
	}

	set machine_switch_trigger_id [after machine_switch [namespace code music_keyboard_reset]]
}

proc update_keyboard {} {
	variable keyb_dict
	variable num_notes
	variable note_strings
	variable note_key_color
	variable frame_trigger_id

	dict for {soundchip chip_dict} $keyb_dict {
		dict for {channel chan_dict} $chip_dict {
			set freq_expr [dict get $chan_dict freq_expr]
			set vol_expr  [dict get $chan_dict vol_expr]
			set prev_note [dict get $chan_dict prev_note]

			set note [expr {round([freq_to_note [eval $freq_expr]])}]
			if {$note != $prev_note} {
				osd configure music_keyboard.chip${soundchip}ch${channel}.key${prev_note} \
					-rgb [dict get $note_key_color $prev_note]
			}
			if {($note < $num_notes) && ($note > 0)} {
				set volume [eval $vol_expr]
				set deviation [expr {round(255 * $volume)}]
				set color [dict get $note_key_color $note]
				set color [expr {($color > 0x808080)
				                 ? ($color - (($deviation << 8) + $deviation))
				                 : ($color + ($deviation << 16))}]
				osd configure music_keyboard.chip${soundchip}ch${channel}.key${note} \
					-rgb $color

				if {$deviation > 0} {
					set note_text [lindex $note_strings [expr {$note % 12}]]
				} else {
					set note_text ""
				}
				dict set keyb_dict $soundchip $channel prev_note $note
			} else {
				set note_text ""
			}
			osd configure music_keyboard.ch${channel}chip${soundchip}infofield.notetext \
				-text $note_text
		}
	}
	set frame_trigger_id [after frame [namespace code update_keyboard]]
}

proc music_keyboard_reset {} {
	if {![osd exists music_keyboard]} {
		error "Please fix a bug in this script!"
	}
	toggle_music_keyboard
	toggle_music_keyboard
}

proc toggle_music_keyboard {} {
	variable machine_switch_trigger_id
	variable frame_trigger_id
	variable keyb_dict

	if {[osd exists music_keyboard]} {
		after cancel $machine_switch_trigger_id
		after cancel $frame_trigger_id
		osd destroy music_keyboard
		unset keyb_dict
	} else {
		keyboard_init
		update_keyboard
	}
	return ""
}

namespace export toggle_music_keyboard

} ;# namespace music_keyboard

namespace import music_keyboard::*
