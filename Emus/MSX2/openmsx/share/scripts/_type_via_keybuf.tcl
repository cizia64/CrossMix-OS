namespace eval type_via_keybuf {

# Based on NYYRIKKI's code found here:
# https://www.msx.org/forum/msx-talk/openmsx/lost-somewhere-inside-openmsx-please-save-me?page=0

set_help_text type_via_keybuf \
{This is an alternative to type_via_keyboard. It's a lot faster, but it only
works in software that reads the input from the keyboard buffer area in the
RAM. In MSX-BASIC, this one works very well. It simply pokes the bytes of the
argument directly into the keyboard buffer.
}

variable bp_id "invalid"
variable the_text
variable index

proc type_via_keybuf {args} {
	set text ""
	# note: ignore extra args to be able to be an alias for the original type command
	while {[llength $args] > 0} {
		set option [lindex $args 0]
		switch -- $option {
			"-release" {
				set args [lrange $args 1 end]
			}
			"-freq" {
				set args [lrange $args 2 end]
			}
			default {
				if {$text ne ""} {
					error "Syntax error"
				}
				set text $option
				set args [lrange $args 1 end]
			}
		}
	}
	variable bp_id

	if {$bp_id ne "invalid"} {
		# already typing going on, so append
		variable the_text
		append the_text $text
		return ""
	}

	variable the_text
	variable index

	set index 0
	set the_text $text
	set bp_id [debug set_bp 0x38 {} "type_via_keybuf::handleinterrupt"]
	return ""
}

proc handleinterrupt {} {
	if {[machine_info type] eq "SVI"} {
	       set PUTPNT 0xFA1A
	       set GETPNT 0xFA1C
	       set KEYBUF 0xFD8B
	       set BUFEND 0xFDB3
	} else {
	       set PUTPNT 0xF3F8
	       set GETPNT 0xF3FA
	       set KEYBUF 0xFBF0
	       set BUFEND 0xFC18
	}

	if {[peek16 $PUTPNT] == [peek16 $GETPNT]} {
		# keyboard buffer is processed

		# poke the buffer (almost!) full with the next file content
		set addr $KEYBUF
		while {$addr < $BUFEND - 1} {
			variable index
			variable the_text
			set char [string index $the_text $index]
			if {$char eq ""} {
				# apparently end of string reached, clean up
				variable bp_id
				debug remove_bp $bp_id
				set bp_id "invalid"
				break
			}
			# do not skip newlines, similar to normal type command
			poke $addr [scan $char "%c"]
			incr addr
			incr index
		}
		# put the end of the data pointer to addr
		poke16 $PUTPNT $addr
		# put read pointer at start of keyboard buffer
		poke16 $GETPNT $KEYBUF
	}
}

namespace export type_via_keybuf

} ;# namespace type_via_keybuf

namespace import type_via_keybuf::*
