# evaluate in internal openmsx namespace
namespace eval openmsx {

variable init_tcl_executed false
variable tabcompletion_proc_sensitive
variable tabcompletion_proc_insensitive
variable help_text
variable help_proc
variable lazy [dict create]

# Only execute this script once. Below we source other Tcl script,
# so this makes sure we don't get in an infinite loop.
if {$init_tcl_executed} return
set init_tcl_executed true

# Debug pints (disabled by default).
proc dbg {msg} {
	#puts stderr $msg
}

# Helpers to handle on-demand (lazy) loading of Tcl scripts

# Register 'script' to be loaded on-demand when one of the proc names in
# 'procs' is about to be executed. See also 'lazy.tcl'.
proc register_lazy {script procs} {
	variable lazy
	dict set lazy $script $procs
}

# Lookup the script associated with the given proc name. If found that script
# is executed (and the script+proc-names are removed from the list of
# yet-to-be-executed lazy scripts).
proc lazy_handler {name} {
	variable lazy
	set name [namespace tail $name]
	dict for {script procs} $lazy {
		if {[lsearch -exact $procs $name] == -1} continue
		dict unset lazy $script
		dbg "start executing script $script (via lazy_handler)"
		if {[catch {namespace eval :: [list source [data_file scripts/$script]]}]} {
			puts stderr "Error while (lazily) loading Tcl script: $script\n$::errorInfo"
			error $::errorInfo
		}
		dbg "done executing script $script"
		return true
	}
	return false
}

# Execute all not yet executed lazy-scripts. ATM this is (only) required for
# the 'about' command which has to search through the help text of all the
# scripts.
proc lazy_execute_all {} {
	variable lazy
	# cannot simply iterate because the 'source' command below might
	# trigger a load of a script later in the collection
	while {[dict size $lazy] != 0} {
		set script [lindex [dict keys $lazy] 0]
		dict unset lazy $script
		dbg "start executing script $script (via lazy_execute_all)"
		if {[catch {namespace eval :: [list source [data_file scripts/$script]]}]} {
			puts stderr "Error while (lazily) loading Tcl script: $script\n$::errorInfo"
			error $::errorInfo
		}
		dbg "done executing script $script"
	}
}

# Return a list of all command names. This includes:
#   builtin Tcl commands,
#   procs defined in Tcl scripts,
#   procs from not yet loaded lazy-scripts (see register_lazy).
# This helper proc is used for tab-completion in the openMSX console.
proc all_command_names {} {
	variable lazy
	set result [info commands]
	foreach procs [dict values $lazy] {
		lappend result {*}$procs
	}
	# only one level deep, good enough for machineN::*
	foreach ns [namespace children ::] {
		lappend result {*}[info commands ${ns}::*]
	}
	return $result
}

# Returns a list of Tcl commands that provide extra help (text or proc).
# Note: there may also be commands implemented in c++ which provide help.
proc all_command_names_with_help {} {
	lazy_execute_all
	set result [array names ::openmsx::help_text]
	lappend result {*}[array names ::openmsx::help_proc]
	return $result
}

# Is the given name a name of a proc, possibly a name defined in a not-yet
# loaded script. This helper proc is used for syntax-highlighting in the
# openMSX console.
proc is_command_name {name} {
	if {[info commands ::$name] ne ""} {return 1}
	expr {[lsearch -exact [all_command_names] [namespace tail $name]] != -1}
}

# Override the builtin Tcl proc 'unknown'. This is called when the Tcl
# interpreter is about to execute an undefined command.
proc ::unknown {args} {
	#puts stderr "unknown: $args"
	set name [lindex $args 0]
	if {[openmsx::lazy_handler $name]} {
		return [uplevel 1 $args]
	}
	return -code error "invalid command name \"$name\""
}


# internal proc to make help function available to Tcl procs
proc help {args} {
	variable help_text
	variable help_proc

	set command [lindex $args 0]
	lazy_handler $command
	if {[info exists help_proc($command)]} {
		return [namespace eval :: $help_proc($command) $args]
	} elseif {[info exists help_text($command)]} {
		return $help_text($command)
	} elseif {[info commands $command] ne ""} {
		error "No help for command: $command"
	} else {
		error "Unknown command: $command"
	}
}
proc set_help_text {command help} {
	variable help_text
	set help_text($command) $help
}
set_help_text set_help_text \
{Associate a help-text with a Tcl proc. This is normally only used in Tcl scripts.}

proc set_help_proc {command procname} {
	variable help_proc
	set help_proc($command) $procname
}
set_help_text set_help_proc \
{Associate a help-proc with a Tcl proc. This is normally only used in Tcl scripts.}

# internal proc to make tabcompletion available to Tcl procs
proc tabcompletion {args} {
	variable tabcompletion_proc_sensitive
	variable tabcompletion_proc_insensitive

	set command [lindex $args 0]
	lazy_handler $command
	set result ""
	if {[info exists tabcompletion_proc_sensitive($command)]} {
		set result [namespace eval :: $tabcompletion_proc_sensitive($command) $args]
		lappend result true
	} elseif {[info exists tabcompletion_proc_insensitive($command)]} {
		set result [namespace eval :: $tabcompletion_proc_insensitive($command) $args]
		lappend result false
	}
	return $result
}
proc set_tabcompletion_proc {command proc {case_sensitive true}} {
	variable tabcompletion_proc_sensitive
	variable tabcompletion_proc_insensitive
	if {$case_sensitive} {
		set tabcompletion_proc_sensitive($command) $proc
	} else {
		set tabcompletion_proc_insensitive($command) $proc
	}
}
set_help_text set_tabcompletion_proc \
{Provide a way to do tab-completion for a certain Tcl proc. For details look at the numerous examples in the share/scripts directory. This is normally only used in Tcl scripts.}

set_help_text data_file \
"Resolve data file. First try user directory, if the file doesn't exist
there try the system directory."
proc data_file { file } {
	global env
	set user_file $env(OPENMSX_USER_DATA)/$file
	if {[file exists $user_file]} { return $user_file }
	return $env(OPENMSX_SYSTEM_DATA)/$file
}

namespace export register_lazy
namespace export set_help_text
namespace export set_help_proc
namespace export set_tabcompletion_proc
namespace export data_file

} ;# namespace openmsx

namespace import openmsx::*

namespace eval openmsx {

# Source all .tcl files in user and system scripts directory. Prefer
# the version in the user directory in case a script exists in both
set user_scripts [glob -dir $env(OPENMSX_USER_DATA)/scripts -tails -nocomplain *.tcl]
set system_scripts [glob -dir $env(OPENMSX_SYSTEM_DATA)/scripts -tails -nocomplain *.tcl]
set profile_list [list]
foreach script [lsort -unique [concat $user_scripts $system_scripts]] {
	# Skip scripts that start with a '_' character. (By convention) those
	# are loaded on-demand (see 'lazy.tcl').
	if {[string index $script 0] eq "_"} continue
	set script [data_file scripts/$script]
	set t1 [openmsx_info realtime]
	dbg "start executing script $script (via startup sequence)"
	if {[catch {namespace eval :: [list source $script]}]} {
		puts stderr "Error while executing $script\n$errorInfo"
	}
	dbg "done executing script $script"
	set t2 [openmsx_info realtime]
	lappend profile_list [list [expr {int(1000000 * ($t2 - $t1))}] $script]
}
if 0 {
	foreach e [lsort -integer -index 0 $profile_list] { puts stderr $e }
}

} ;# namespace openmsx
