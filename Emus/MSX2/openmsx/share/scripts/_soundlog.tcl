namespace eval soundlog {

# Backwards compatibility:
#  The 'soundlog' command used to be a built-in openmsx command.
#  Reimplemented now via the 'record -audioonly' command.

set_help_text soundlog \
{Controls sound logging: writing the openMSX sound to a wav file.
soundlog start              Log sound to file "openmsxNNNN.wav"
soundlog start <filename>   Log sound to indicated file
soundlog start -prefix foo  Log sound to file "fooNNNN.wav"
soundlog stop               Stop logging sound
soundlog toggle             Toggle sound logging state
}

set_tabcompletion_proc soundlog [namespace code soundlog_tab]
proc soundlog_tab {args} {
	if {[llength $args] == 2} {
		return [list "start" "stop" "toggle"]
	} elseif {[llength $args] == 3 && [lindex $args 2] eq "start"} {
		return [list "-prefix"]
	}
	return [list]
}

proc soundlog {args} {
	if {$args eq [list "stop"]} {
		record stop
	} else {
		record {*}$args -audioonly
	}
}

namespace export soundlog

} ;# namespace soundlog

namespace import soundlog::*
