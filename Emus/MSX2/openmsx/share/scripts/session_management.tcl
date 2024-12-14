# this file implements machine session management

namespace eval session_management {

set_help_text save_session \
{save_session [<name>]

Saves the state of all your currently running machines as a session with the
given name.
Any existing session with that name will be silently overwritten.

See also 'load_session', 'list_sessions' and 'delete_session'.
}

set_help_text load_session \
{load_session <name>

Restores the state of all machines of the session with the given name and
reactivates the machine that was active at save time. Note: all machines
already running will be silently destroyed! (Unless no single machine succeeded
to be restored.)

See also 'save_session', 'list_sessions' and 'delete_session'.
}

set_help_text list_sessions \
{list_sessions

Returns the names of all previously saved sessions.

See also 'save_session', 'load_session' and 'delete_session'.
}

set_help_text delete_session \
{delete_session <name>

Delete a previously saved session.

See also 'save_session', 'load_session' and 'list_sessions'.
}


user_setting create boolean enable_session_management "Whether to save your session at exit and restore it again at start up." false

proc tabcompletion {args} {
	return [list_sessions]
}

set_tabcompletion_proc load_session [namespace code tabcompletion]
set_tabcompletion_proc save_session [namespace code tabcompletion]
set_tabcompletion_proc delete_session [namespace code tabcompletion]

proc delete_session {name} {
	set directory [file normalize $::env(OPENMSX_USER_DATA)/../sessions/${name}]

	# remove old session under this name
	file delete -force -- $directory
}

proc list_sessions {} {
	set directory [file normalize $::env(OPENMSX_USER_DATA)/../sessions]
	return [lsort [glob -tails -directory $directory -type d -nocomplain *]]
}

proc get_machine_representation {machine_id} {
	return "[utils::get_machine_display_name $machine_id] @ [utils::get_machine_time $machine_id]"
}

proc save_session {{name "untitled"}} {
	if {[llength [list_machines]] == 0} {
		return "Nothing to save..."
	}

	set result ""

	set directory [file normalize $::env(OPENMSX_USER_DATA)/../sessions/${name}]

	# remove old session under this name
	delete_session $name
	file mkdir $directory

	# save using ID as file names
	foreach machine [list_machines] {
		append result "Saving machine $machine ([get_machine_representation $machine])...\n"
		store_machine $machine [file join $directory ${machine}.oms]
	}
	# save in a separate file the currently active machine
	set fileId [open [file join $directory active_machine] "w"]
	puts $fileId [format "%s.oms" [machine]]
	close $fileId

	append result "Session saved as $name\n"
	return $result
}

proc load_session {name} {
	set result ""

	# get all savestate files
	set directory [file normalize $::env(OPENMSX_USER_DATA)/../sessions/${name}]
	set states_to_restore [glob -tails -directory $directory -nocomplain *.oms *.xml.gz]

	# abort if we have nothing to restore
	if {[llength $states_to_restore] == 0} {
		error "Nothing found to restore..."
	}

	# sort them in order of ID, to guarantee consistent order as saved
	set states_to_restore [lsort -dictionary $states_to_restore]

	# save the machines we start with
	set orginal_machines [list_machines]

	# try to load file with active machine
	set active_machine ""
	catch {
		set fp [open [file join $directory active_machine] "r"]
		set active_machine [read -nonewline $fp]
		close $fp
	}

	# restore all saved machines
	set first true
	foreach state $states_to_restore {
		set fullname [file join $directory $state]
		if {[catch { ;# skip machines failing to restore
			set newID [restore_machine $fullname]
			append result "Restored $state as $newID ([get_machine_representation $newID])...\n"
			# activate saved active machine or alternatively, first machine
			if {(($active_machine ne "") && ($state eq $active_machine)) || \
			    (($active_machine eq "") && $first)} {
				activate_machine $newID
			}
			set first false
		} error_result]} {
			append result "Skipping $state: $error_result\n"
		}
	}

	# if restoring at least one machine succeeded, delete all original machines
	if {[llength [list_machines]] > [llength $orginal_machines]} {
		foreach machine $orginal_machines {
			delete_machine $machine
		}
	} else {
		append result "Couldn't restore a single machine, aborting...\n"
	}

	# if the active machine failed to load, activate the first machine (if available):
	if {[activate_machine] eq "" && [llength [list_machines]] > 0} {
		activate_machine [lindex [list_machines] 0]
	}

	return $result
}

variable after_quit_id

# do actual session management
if {$::enable_session_management} {
	# need after realtime command here, because openMSX needs to have started up first
	after realtime 0 {load_session "default_session"}
	set after_quit_id [after quit {save_session "default_session"}]
}

proc setting_changed {name1 name2 op} {
	variable after_quit_id

	if {$::enable_session_management} {;# setting changed from disabled to enabled
		set after_quit_id [after quit {save_session "default_session"}]
	} else { ;# setting changed from enabled to disabled
		after cancel $after_quit_id
	}
}

trace add variable ::enable_session_management "write" [namespace code setting_changed]

namespace export save_session
namespace export load_session
namespace export list_sessions
namespace export delete_session

} ;# namespace session_management

namespace import session_management::*
