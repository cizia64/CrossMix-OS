namespace eval about {

set_help_text about \
"Shows a list of commands and/or settings that seem related to the given keyword.
If there is only one such command or setting the helptext for that command or
setting is also shown."

proc about {keyword} {
	openmsx::lazy_execute_all
	set command_matches [get_matching_commands $keyword]
	set setting_matches [get_matching_settings $keyword]
	set result ""
	set lc [llength $command_matches]
	set ls [llength $setting_matches]
	if {$lc == 0  && $ls == 0} {
		error "No candidates found."
	} elseif {$lc == 1 && $ls == 0} {
		set match [lindex $command_matches 0]
		append result "Command $match:\n"
		append result "[help $match]\n"
	} elseif {$lc == 0 && $ls == 1} {
		set match [lindex $setting_matches 0]
		append result "Setting $match:\n"
		append result "[help set $match]\n"
	} else {
		append result "Multiple candidates found:\n"
		foreach match $command_matches {
			append result "  command: $match\n"
		}
		foreach match $setting_matches {
			append result "  setting: $match\n"
		}
	}
	return $result
}

proc get_matching_commands {keyword} {
	set matches [list]
	foreach command [info commands] {
		catch {
			if {[regexp -nocase -- $keyword [help $command]] ||
			    ($command eq $keyword)} {
				lappend matches $command
			}
		}
	}
	return $matches
}

proc get_matching_settings {keyword} {
	set matches [list]
	foreach setting [openmsx_info setting] {
		catch {
			if {[regexp -nocase -- $keyword [help set $setting]] ||
			    ($setting eq $keyword)} {
				lappend matches $setting
			}
		}
	}
	return $matches
}

namespace export about

} ;# namespace about

namespace import about::*
