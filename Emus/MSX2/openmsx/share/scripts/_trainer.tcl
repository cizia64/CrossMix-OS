namespace eval trainer {

set_help_text trainer "
Usage:
  trainer                      see which trainer is currently active
  trainer <game>               see which cheats are currently active in the trainer
  trainer <game> all           activate all cheats in the trainer
  trainer <game> \[<cheat> ..\]  toggle cheats on/off
  trainer deactivate           deactivate trainers

Examples:
  trainer Frogger all
  trainer Circus\ Charlie 1 2
  trainer Pippols lives \"jump shoes\"\

When switching trainers, the currently active trainer will be deactivated.
"

variable trainers ""
variable active_trainer ""
variable items_active
variable after_id 0

proc load_trainers {} {
	variable trainers
	if {[dict size $trainers] == 0} {
		# source the trainer definitions (user may override system defaults) and ignore errors
		catch {source $::env(OPENMSX_SYSTEM_DATA)/scripts/_trainerdefs.tcl}
		catch {source $::env(OPENMSX_USER_DATA)/scripts/_trainerdefs.tcl}
	}
	return $trainers
}

set_tabcompletion_proc trainer [namespace code tab_trainer] false
proc tab_trainer {args} {
	set trainers [load_trainers]
	if {[llength $args] == 2} {
		set result [dict keys $trainers]
		lappend result "deactivate"
	} else {
		set result [list]
		set name [lindex $args 1]
		if {[dict exists $trainers $name]} {
			set items [dict get $trainers $name items]
			set i 1
			foreach {item_name item_impl} $items {
				lappend result $item_name $i
				incr i
			}
		}
		lappend result "all"
	}
	return $result
}

proc trainer {args} {
	variable active_trainer
	variable items_active
	set trainers [load_trainers]

	if {[llength $args] > 0} {
		set name [lindex $args 0]
		if {$name ne "deactivate"} {
			set requested_items [lrange $args 1 end]
			if {![dict exists $trainers $name]} {
				error "no trainer for $name."
			}
			set same_trainer [string equal $name $active_trainer]
			set items [parse_items $name $requested_items]
			if {$same_trainer} {
				set new_items [list]
				foreach item1 $items item2 $items_active {
					lappend new_items [expr {$item1 ^ $item2}]
				}
				set items_active $new_items
			} else {
				deactivate
				set active_trainer $name
				set items_active $items
				execute
			}
		} else {
			deactivate
			return ""
		}
	}
	print
}
proc parse_items {name requested_items} {
	variable trainers
	set items [dict get $trainers $name items]
	set result [list]
	set i 1
	foreach {item_name item_impl} $items {
		lappend result [expr {($requested_items eq "all")      ||
		                      ($i         in $requested_items) ||
		                      ($item_name in $requested_items)}]
		incr i
	}
	return $result
}
proc print {} {
	variable trainers
	variable active_trainer
	variable items_active

	if {$active_trainer eq ""} {
		return "no trainer active"
	}
	set result [list]
	set items [dict get $trainers $active_trainer items]
	lappend result "active trainer: $active_trainer"
	set i 1
	foreach {item_name item_impl} $items item_active $items_active {
		set line "$i \["
		append line [expr {$item_active ? "x" : " "}]
		append line "\] $item_name"
		lappend result $line
		incr i
	}
	join $result \n
}
proc execute {} {
	variable trainers
	variable active_trainer
	variable items_active
	variable after_id

	set items  [dict get $trainers $active_trainer items ]
	set repeat [dict get $trainers $active_trainer repeat]
	foreach {item_name item_impl} $items item_active $items_active {
		if {$item_active} {
			eval $item_impl
		}
	}
	set after_id [after {*}$repeat trainer::execute]
}
proc deactivate {} {
	variable after_id
	variable active_trainer

	after cancel $after_id
	set active_trainer ""
}
proc deactivate_after {event} {
	deactivate
	after $event "trainer::deactivate_after $event"
}
deactivate_after boot
deactivate_after machine_switch

proc create_trainer {name repeat items} {
	variable trainers
	dict set trainers $name [dict create items $items repeat $repeat]
}

namespace export trainer

} ;# namespace trainer

namespace import trainer::*
