# if this machine has a cassetteport, then automatically plug
# in the cassetteplayer
# on a Dingoo, automatically plug in the keyjoystick and if there are real
# joysticks, plug them as well for non-Dingoo platofrms

proc get_pluggable_for_connector {connector} {
	set t [plug $connector]
	return [string range $t [string first ": " $t]+2 end]
}

namespace eval autoplug {

proc plug_if_empty {connector pluggable} {
	set plugged [get_pluggable_for_connector $connector]
	if {$plugged eq ""} {
		# only when nothing already plugged
		plug $connector $pluggable
	}
}

proc do_autoplug {} {
	# do not do any auto plug stuff when replaying, because a reset
	# command in the replay will trigger autoplug and will cause the
	# replay to get interrupted with the plug event.
	if {[dict get [reverse status] status] ne "replaying"} {
		set connectors [list]
		catch {
			#can fail when you activate an 'empty' machine
			set connectors [machine_info connector]
		}
		set pluggables [list]
		catch {
			#can fail when you activate an 'empty' machine
			set pluggables [machine_info pluggable]
		}

		# cassette port
		if {"cassetteport" in $connectors} {
			plug_if_empty cassetteport cassetteplayer
		}

		# joystick ports
		if {[string match *-dingux* $::tcl_platform(osVersion)]} { ;# Dingoo
			if {"joyporta" in $connectors} {
				set ::keyjoystick1.triga LCTRL
				set ::keyjoystick1.trigb LALT
				plug_if_empty joyporta keyjoystick1
			}
		} else {
			if {("joyporta" in $connectors) &&
			    ("joystick1" in $pluggables)} {
				plug_if_empty joyporta joystick1
			}
			if {("joyportb" in $connectors) &&
			    ("joystick2" in $pluggables)} {
				plug_if_empty joyportb joystick2
			}
		}
	}
	after boot [namespace code do_autoplug]
}

};# namespace autoplug

after boot autoplug::do_autoplug
