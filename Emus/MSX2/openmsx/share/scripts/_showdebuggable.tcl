namespace eval showdebuggable {

#
# show_debuggable
#
set_help_text showdebuggable \
{Print content of debuggable nicely formatted

Usage:
   showdebuggable <debuggable> <address> [<linecount>]
}

set_tabcompletion_proc showdebuggable [namespace code tab_showdebuggable]
proc tab_showdebuggable {args} {
	if {[llength $args] == 2} {
		return [debug list]
	}
}

proc showdebuggable_line {debuggable address} {
	set size [debug size $debuggable]
	set num [expr {(($address + 16) <= $size) ? 16 : ($size - $address)}]
	set mem "[debug read_block $debuggable $address $num]"
	binary scan $mem c* values
	set hex ""
	foreach val $values {
		append hex [format "%02x " [expr {$val & 0xff}]]
	}
	set pad [string repeat "   " [expr {16 - $num}]]
	set asc [regsub -all {[^ !-~]} $mem {.}]
	return [format "%04x: %s%s %s\n" $address $hex $pad $asc]
}

proc showdebuggable {debuggable {address 0} {lines 8}} {
	set result ""
	for {set i 0} {$i < $lines} {incr i} {
		if {$address >= [debug size $debuggable]} break
		append result [showdebuggable_line $debuggable $address]
		incr address 16
	}
	return $result
}

# Some stuff for backwards compatibility. Do we want to deprecate them?
# I prefer to keep this as a convenience function.
set_help_text showmem \
{Print the content of the CPU visible memory nicely formatted
This is a shortcut for 'showdebuggable memory <address>'.

Usage:
   showmem <address> [<linecount>]
}

proc showmem {{address 0} {lines 8}} {
	showdebuggable memory $address $lines
}

namespace export showdebuggable
namespace export showmem

} ;# namespace showdebuggable

namespace import showdebuggable::*
