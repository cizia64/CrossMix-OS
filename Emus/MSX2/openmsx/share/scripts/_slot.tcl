namespace eval slot {

#
# get_selected_slot
#
set_help_text get_selected_slot \
{Returns the selected slot for the given memory page.
This proc is typically used as a helper for a larger proc.

 @param page The memory page (0-3)
 @result Returns a Tcl list with two elements.
         First element is the primary slot (0-3).
         Second element is the secondary slot (0-3) or 'X'
         in case this slot was not expanded
}
proc get_selected_slot {page} {
	set ps_reg [debug read "ioports" 0xA8]
	set ps [expr {($ps_reg >> (2 * $page)) & 0x03}]
	if {[machine_info "issubslotted" $ps]} {
		set ss_reg [debug read "slotted memory" [expr {0x40000 * $ps + 0xFFFF}]]
		set ss [expr {(($ss_reg ^ 255) >> (2 * $page)) & 0x03}]
	} else {
		set ss "X"
	}
	list $ps $ss
}

#
# slotselect
#
set_help_text slotselect \
{Returns a nicely formatted overview of the selected slots.}
proc slotselect {} {
	set result ""
	for {set page 0} {$page < 4} {incr page} {
		lassign [get_selected_slot $page] ps ss
		append result [format "%04X: slot %d" [expr {0x4000 * $page}] $ps]
		if {$ss ne "X"} {append result "." $ss}
		append result "\n"
	}
	return $result
}

#
# get_mapper_size
#
set_help_text get_mapper_size \
{Returns the size of the memory mapper in a given slot.
Result is 0 when there is no memory mapper in the slot.}
proc get_mapper_size {ps ss} {
	set result 0
	catch { ;# for multi-mem devices, but those aren't memory mappers
		set device [lindex [machine_info slot $ps $ss 0] 0]
		if {[debug desc $device] eq "memory mapper"} {
			set result [expr {[debug size $device] / 0x4000}]
		}
	}
	return $result
}

#
# get (rom) block size
# e.g. for a 'Konami' rom mapper it returns 8kB
# TODO it would be nice to generalize this so that it also works for memory
# mappers, or even all memory mapped devices (whether they have switchable
# blocks or not)
#
proc get_block_size {ps ss page} {
	set block_size 0
	catch {
		set device_list [machine_info slot $ps $ss $page]
		if {[llength $device_list] != 1} {return 0}
		set device_info [machine_info device [lindex $device_list 0]]
		set romtype [dict get $device_info "mappertype"] ;# can return ""
		set romtype_info [openmsx_info romtype $romtype] ;# fails if romtype == ""
		set block_size [dict get $romtype_info blocksize];# could fail??
	}
	return $block_size
}

#
# pc_in_slot
#
set_help_text pc_in_slot \
{Test whether the CPU's program counter is inside a certain slot.
Typically used to set breakpoints in specific slots.}
proc pc_in_slot {ps {ss "X"} {mapper "X"}} {
	return [address_in_slot [reg PC] $ps $ss $mapper]
}

#
# watch_in_slot
#
set_help_text watch_in_slot \
{Test whether the address watched is inside a certain slot.
To be used only to set watchpoints in specific slots.}
proc watch_in_slot {ps {ss "X"} {mapper "X"}} {
	return [address_in_slot $::wp_last_address $ps $ss $mapper]
}

#
# helper proc for pc_in_slot and watch_in_slot
#
set_help_text address_in_slot \
{Test whether an address is inside a certain slot.
Typically used by pc_in_slot and watch_in_slot.}
proc address_in_slot {addr ps {ss "X"} {block "X"}} {
	# get current page and slots
	set page [expr {$addr >> 14}]
	lassign [get_selected_slot $page] pc_ps pc_ss

	# check primary and secondary slot
	if {($ps ne "X") &&                    ($pc_ps != $ps)} {return 0}
	if {($ss ne "X") && ($pc_ss ne "X") && ($pc_ss != $ss)} {return 0}

	# need to check block?
	if {$block eq "X"} {return true}

	# first (try to) check memory mapper
	if {$pc_ss eq "X"} {set pc_ss 0}
	set mapper_size [get_mapper_size $pc_ps $pc_ss]
	if {$mapper_size != 0} {
		set pc_block [debug read "MapperIO" $page]
		return [expr {$block == ($pc_block & ($mapper_size - 1))}]
	}

	# next (try to) check rom mapper
	set block_size [get_block_size $pc_ps $pc_ss $page]
	if {$block_size != 0} {
		set device_name [lindex [machine_info slot $pc_ps $pc_ss $page] 0]
		# note: I'm assuming that if get_block_size returns a non-zero
		#       value, then the "romblocks" debuggable always exixts.
		#       Is that correct?
		set pc_block [debug read "$device_name romblocks" $addr]
		return [expr {$block == $pc_block}]
	}

	# no mapper present, ok (or should we check block==0 ?)
	return 1
}

#
# slotmap
#
set_help_text slotmap \
{Gives an overview of the devices in the different slots.}
proc slotmap_helper {ps ss} {
	set result ""
	for {set page 0} {$page < 4} {incr page} {
		set device_list [machine_info slot $ps $ss $page]
		# This 'if' introduces a parsing ambiguity (list of elements
		# without embedded spaces versus single element with embedded
		# spaces) though usually this looks nicer.
		# Though this means the output of this script should not be
		# further parsed in scripts.
		if {[llength $device_list] == 1} {
			set name [lindex $device_list 0]
		} else {
			set name $device_list
		}
		append result [format "%04X: %s\n" [expr {$page * 0x4000}] $name]
	}
	return $result
}
proc slotmap_name {ps ss} {
	set t [list $ps $ss]
	foreach slot [machine_info external_slot] {
		if {[lrange [machine_info external_slot $slot] 0 1] eq $t} {
			return " (${slot})"
		}
	}
	return ""
}
proc slotmap {} {
	set result ""
	for {set ps 0} {$ps < 4} {incr ps} {
		if {[machine_info issubslotted $ps]} {
			for {set ss 0} {$ss < 4} {incr ss} {
				append result "slot $ps.$ss[slotmap_name $ps $ss]:\n"
				append result [slotmap_helper $ps $ss]
			}
		} else {
			append result "slot $ps[slotmap_name $ps X]:\n"
			append result [slotmap_helper $ps 0]
		}
	}
	return $result
}

#
# iomap
#
set_help_text iomap \
{Gives an overview of the devices connected to the different I/O ports.}
proc iomap_helper {prefix begin end name} {
	if {$name eq ""} {return ""}
	set result [format "port %02X" $begin]
	if {$begin == ($end - 1)} {
		append result ":   "
	} else {
		append result [format "-%02X:" [expr {$end - 1}]]
	}
	append result " $prefix $name\n"
}
proc iomap {} {
	set result ""
	set port 0
	while {$port < 256} {
		set in  [machine_info input_port  $port]
		set out [machine_info output_port $port]
		set end [expr {$port + 1}]
		while {($end < 256) &&
		       ($in  eq [machine_info input_port  $end]) &&
		       ($out eq [machine_info output_port $end])} {
			incr end
		}
		if {$in eq $out} {
			append result [iomap_helper "I/O" $port $end $in ]
		} else {
			append result [iomap_helper "I  " $port $end $in ]
			append result [iomap_helper "  O" $port $end $out]
		}
		set port $end
	}
	return $result
}

namespace export get_selected_slot
namespace export slotselect
namespace export get_mapper_size
namespace export pc_in_slot
namespace export watch_in_slot
namespace export address_in_slot
namespace export slotmap
namespace export iomap

} ;# namespace slot

namespace import slot::*
