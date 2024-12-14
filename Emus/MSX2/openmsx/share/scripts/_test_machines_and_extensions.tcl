# TCL script for openMSX for easy testing of known machines and extensions.
# (c) 2012 Filip H.F. "FiXato" Slagter
# For inclusion with openMSX, GNU General Public License version 2 (GPLv2,
# http://www.gnu.org/licenses/gpl-2.0.html) applies.
# Otherwise you may use this work without restrictions, as long as this notice
# is included.
# The work is provided "as is" without warranty of any kind, neither express
# nor implied.

set_help_text test_all_machines "Test all known machines and report errors. Pass 'stderr' as channel argument to get the return values on the commandline."

proc test_all_machines {{channel "stdout"}} {
	set nof_machines [llength [openmsx_info machines]]
	set broken [list]
	set errors [list]
	puts $channel "Going to test $nof_machines machines..."
	foreach machine [openmsx_info machines] {
		puts -nonewline $channel "Testing $machine ([utils::get_machine_display_name_by_config_name $machine])... "
		set res [test_machine $machine]
		if {$res != ""} {
			lappend broken $machine
			lappend errors $res
			set res "BROKEN: $res"
		} else {
			set res "OK"
		}
		puts $channel $res
	}
	set nof_ok [expr {$nof_machines - [llength $broken]}]
	set perc [expr {($nof_ok*100)/$nof_machines}]
	puts $channel ""
	puts $channel "$nof_ok out of $nof_machines machines OK ($perc\%)"
	if {$nof_ok < $nof_machines} {
		puts $channel ""
		puts $channel "Broken machines:"
		foreach machine $broken errormsg $errors {
			puts $channel "  $machine ([utils::get_machine_display_name_by_config_name $machine]): $errormsg"
		}
	}
}

set_help_text test_all_extensions "Test all known extensions and report errors. Defaults to using your current machine profile. You can optionally specify another machine configuration name to test on that profile. Pass 'stderr' as last argument to get the return values on the commandline."

proc test_all_extensions {{machine ""} {channel "stdout"}} {

	if {$machine == ""} {
		set machine [machine_info config_name]
	}

	# Start a new machine to prevent any conflicts
	machine $machine

	set nof_extensions [llength [openmsx_info extensions]]
	set broken [list]
	set errors [list]
	puts $channel "Going to test $nof_extensions extensions on machine \"[utils::get_machine_display_name_by_config_name $machine]\"..."
	foreach extension [openmsx_info extensions] {
		# Try to plug in the extension and output any errors to the
		# given channel (defaults to stdout aka the openMSX console)
		puts -nonewline $channel "Testing $extension ([utils::get_extension_display_name_by_config_name $extension])... "
		set res ""
		if { [catch {ext $extension} errorText] } {
			lappend broken $extension
			lappend errors $errorText
			set res "BROKEN: $errorText"
		} else {
			set res "OK"
			incr nof_ok
			remove_extension $extension
		}
		puts $channel $res
	}
	set nof_ok [expr {$nof_extensions - [llength $broken]}]
	set perc [expr {($nof_ok*100)/$nof_extensions}]
	puts $channel ""
	puts $channel "$nof_ok out of $nof_extensions extensions OK ($perc\%)"
	if {$nof_ok < $nof_extensions} {
		puts $channel ""
		puts $channel "Broken extensions:"
		foreach extension $broken errormsg $errors {
			puts $channel "  $extension ([utils::get_extension_display_name_by_config_name $extension]): $errormsg"
		}
	}
}
