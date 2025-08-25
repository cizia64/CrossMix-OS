namespace eval cycle {

set help_cycle \
{Cycle through the possible values of an enum setting.
'cycle_back' does the same as 'cycle', but it goes in the opposite direction.

Usage:
  cycle      <enum_setting> [<cycle_list>]
  cycle_back <enum_setting> [<cycle_list>]

Example:
  cycle scale_algorithm
  cycle scale_algorithm "hq2x hq2xlite"
}

set_help_text cycle      $help_cycle
set_help_text cycle_back $help_cycle
set_tabcompletion_proc cycle      [namespace code tab_cycle]
set_tabcompletion_proc cycle_back [namespace code tab_cycle]

proc tab_cycle {args} {
	set result [list]
	foreach setting [openmsx_info setting] {
		set type [lindex [openmsx_info setting $setting] 0]
		if {($type eq "enumeration") || ($type eq "boolean")} {
			lappend result $setting
		}
	}
	return $result
}

proc cycle {setting {cycle_list {}} {step 1}} {
	set setting_info [openmsx_info setting $setting]
	set type [lindex $setting_info 0]
	if {$type eq "enumeration"} {
		if {[llength $cycle_list] == 0} {
			set cycle_list [lindex $setting_info 2]
		}
	} elseif {$type eq "boolean"} {
		set cycle_list [list "true" "false"]
	} else {
		error "Not an enumeration setting: $setting"
	}
	set cur [lsearch -exact -nocase $cycle_list [set ::$setting]]
	set new [expr {($cur + $step) % [llength $cycle_list]}]
	set ::$setting [lindex $cycle_list $new]
}

proc cycle_back {setting} {
	cycle $setting {} -1
}

set_help_text toggle \
{Toggles a boolean setting

Usage:
  toggle <boolean_setting>

Example:
  toggle fullscreen
}

set_tabcompletion_proc toggle [namespace code tab_cycle]

proc toggle {setting} {
        cycle $setting "on off"
}

namespace export cycle
namespace export cycle_back
namespace export toggle

} ;# namespace cycle

namespace import cycle::*
