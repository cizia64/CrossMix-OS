namespace eval vdp_access_test {

# you can tweak these to test for other stuff
# TODO: make this flexible so the timing can be specified for each combination
# of ports and read/write
variable ioports {0x98 0x99}
variable cycle_max 29
# if you set this to true, you can also see OK I/O, but there are many of those!
variable debug false
# if you set this to true, openMSX will break when too fast access happens, so
# you can investigate what's going on with the debug commands (or debugger)
variable enable_break false

variable last_access_time 0
variable last_access_type
variable last_access_port
variable is_enabled false
variable watchpoint_write_id
variable watchpoint_read_id
variable address_list

set_help_text toggle_vdp_access_test \
"Report in the console when VDP I/O is done which could possibly cause data
corruption on the slowest VDP (TMS99xx), i.e. when time between successive I/O
was less than $cycle_max cycles and display was active. Note: this script is
not 100% accurate! Keep testing on a real MSX as well. The script has some
tuning options; edit the script to do so, it's explained at the top what can be
tuned."

proc check_time {access_type} {
	variable last_access_time
	variable last_access_type
	variable last_access_port
	variable cycle_max
	variable debug
	variable enable_break
	variable address_list

	set port [expr {$::wp_last_address & 255}]
	set current_time [machine_info time]
	set cycles [expr {round(3579545 * ($current_time - $last_access_time))}]
	set screen_enabled [expr {[debug read "VDP regs" 1] & 64}]
	set vblank [expr {[debug read "VDP status regs" 2] & 64}]
	set pc [format "%04x" [reg PC]]
	if {($cycles < $cycle_max) && $screen_enabled && !$vblank} {
		if {$pc ni $address_list} {
			set valuetext ""
			if {$access_type eq "write"} {
				set valuetext [format " (value 0x%02X)" $::wp_last_value]
			}
			puts [format "VDP $last_access_type on port 0x%02X followed by a $access_type${valuetext} on port 0x%02X on address $pc and time $current_time with too few cycles in between: $cycles (< $cycle_max)" $last_access_port $port]
			lappend address_list $pc
			set address_list [lsort $address_list]
			puts "Sorted list of addresses where too fast I/O is done: $address_list"
			if {$enable_break} {
				debug break
			}
		}
	} else {
		if {$debug} {
			if {!$screen_enabled} {
				set reason "screen is disabled"
			} elseif {$vblank} {
				set reason "in vblank"
			} else {
				set reason "last access was $cycles cycles ago, >= $cycle_max"
			}
			puts [format "VDP I/O $access_type to port 0x%02X OK on address: 0x$pc, $reason" $port]
		}
	}
	set last_access_time $current_time
	set last_access_port $port
	set last_access_type $access_type
}

proc toggle_vdp_access_test {} {
	variable is_enabled
	variable watchpoint_write_id
	variable watchpoint_read_id
	variable address_list
	variable ioports

	if {!$is_enabled} {
		set watchpoint_write_id [debug set_watchpoint write_io $ioports {} {vdp_access_test::check_time "write"}]
		set watchpoint_read_id  [debug set_watchpoint read_io  $ioports {} {vdp_access_test::check_time "read"}]
		set is_enabled true
		set address_list [list]
	} else {
		debug remove_watchpoint $watchpoint_write_id
		debug remove_watchpoint $watchpoint_read_id
		set is_enabled false
	}
}

namespace export toggle_vdp_access_test

} ;# namespace vdp_access_test

namespace import vdp_access_test::*
