namespace eval cycle_machine {

set help_cycle_machine \
{Cycle through the currently running machines.
'cycle_back_machine' does the same as 'cycle_machine', but it goes in the
opposite direction.
}

set_help_text cycle_machine $help_cycle_machine
set_help_text cycle_back_machine $help_cycle_machine

proc cycle_machine {{step 1}} {
	set cycle_list [utils::get_ordered_machine_list]
	if {[llength $cycle_list] > 0} {
		set cur [lsearch -exact $cycle_list [activate_machine]]
		set new [expr {($cur + $step) % [llength $cycle_list]}]
		activate_machine [lindex $cycle_list $new]
	}
}

proc cycle_back_machine {} {
	cycle_machine -1
}

namespace export cycle_machine
namespace export cycle_back_machine

} ;# namespace cycle_machine

namespace import cycle_machine::*
