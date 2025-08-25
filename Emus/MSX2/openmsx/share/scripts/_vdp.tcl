namespace eval vdp {

set_help_text getcolor \
{Return the current V99x8 palette settings for the given color index (0-15).
The result is format as RGB, with each component in the range 0-7.
}
proc getcolor {index} {
	set rb [debug read "VDP palette" [expr {2 * $index}]]
	set g  [debug read "VDP palette" [expr {2 * $index + 1}]]
	format "%03x" [expr {(($rb * 16) & 0x700) + (($g * 16) & 0x070) + ($rb & 0x007)}]
}

set_help_text setcolor \
{Change the V99x8 palette settings. See also getcolor.

usage:
  setcolor <index> <r><g><b>
   <index>   0-15
   <r><g><b> 0-7
}
proc setcolor {index rgb} {
	if {[catch {
		if {[string length $rgb] != 3} error
		set r [string index $rgb 0]
		set g [string index $rgb 1]
		set b [string index $rgb 2]
		if {($index < 0) || ($index > 15)} error
		if {($r > 7) || ($g > 7) || ($b > 7)} error
		debug write "VDP palette" [expr {$index * 2}] [expr {$r * 16 + $b}]
		debug write "VDP palette" [expr {$index * 2 + 1}] $g
	}]} {
		error "Usage: setcolor <index> <rgb>\n index 0..15\n r,g,b 0..7"
	}
}

proc format_table {entries columns frmt sep func} {
	set result ""
	set rows [expr {($entries + $columns - 1) / $columns}]
	for {set row 0} {$row < $rows} {incr row} {
		set line ""
		for {set col 0} {$col < $columns} {incr col} {
			set index [expr {$row + ($col * $rows)}]
			if {$index < $entries} {
				append line [format $frmt $index [$func $index]] $sep
			}
		}
		append result "${line}\n"
	}
	return $result
}

set_help_text vdpreg "Read or write a V99x8 register."
proc vdpreg {reg {value ""}} {
	if {$value eq ""} {
		debug read "VDP regs" $reg
	} else {
		debug write "VDP regs" $reg $value
	}
}

set_help_text vdpregs "Gives an overview of the V99x8 registers."
proc vdpregs {} {
	format_table 32 4 "%2d : 0x%02x" "   " vdpreg
}

set_help_text v9990reg "Read or write a V9990 register."
proc v9990reg {reg {value ""}} {
	if {$value eq ""} {
		debug read "Sunrise GFX9000 regs" $reg
	} else {
		debug write "Sunrise GFX9000 regs" $reg $value
	}
}

set_help_text v9990regs "Gives an overview of the V9990 registers."
proc v9990regs {} {
	format_table 55 5 "%2d : 0x%02x" "   " v9990reg
}

set_help_text palette "Gives an overview of the V99x8 palette registers."
proc palette {} {
	format_table 16 4 "%x:%s" "  " getcolor
}

proc val2bin val {
	set binRep [binary format c $val]
	binary scan $binRep B* binStr
	return $binStr
}

variable mode_lookup

set mode_lookup(00000000) 1;# Screen 1
set mode_lookup(00000001) "TEXT40";# Screen 0 (WIDTH 40)
set mode_lookup(00000010) 3;# Screen 3
set mode_lookup(00000100) 2;# Screen 2
set mode_lookup(00001000) 4;# Screen 4
set mode_lookup(00001001) "TEXT80";# Screen 0 (WIDTH 80)
set mode_lookup(00001100) 5;# Screen 5
set mode_lookup(00010000) 6;# Screen 6
set mode_lookup(00010100) 7;# Screen 7
set mode_lookup(00011100) 8;# Screen 8

set_help_text get_screen_mode_number "Decodes the current screen mode from the VDP registers (as would be used in the BASIC SCREEN command)"
proc get_screen_mode_number {} {
	set mode [get_screen_mode]
	if {[string range $mode 0 3] eq "TEXT"} {
		return 0
	} elseif {$mode eq "invalid"} {
		return -1
	}
	return $mode
}

set_help_text get_screen_mode "Decodes the current screen mode from the VDP registers (and returns it as a string)."
proc get_screen_mode {} {
	variable mode_lookup
	set val [expr {(([vdpreg 0] & 14) << 1) | (([vdpreg 1] & 8) >> 2) | (([vdpreg 1] & 16) >> 4)}]
	if {[catch {set mode $mode_lookup([val2bin $val])}]} {
		return "invalid"
	}
	if {(($mode == 8) || ($mode == 7)) && ([vdpreg 25] & 8)} {
		set mode [expr {([vdpreg 25] & 16) ? 11 : 12}]
	}
	return $mode
}

set_help_text vpeek \
{Similar to the BASIC vpeek command, read a byte from the video RAM.
This command has the same view on the VRAM as the programmer sees (as opposed
to the physical VRAM content):
 - The whole 128kB address space is visible, if the machine has less VRAM
   then some parts will either be mirrored or unmapped.
 - Depending on the current screen mode, the VRAM addressing is interleaved
   or not. This command follows that addressing scheme (IOW, normally you
   don't have to care).
See also the 'vpoke' command.
}
proc vpeek {addr} {
	debug read VRAM $addr
}

set_help_text vpoke \
{Similar to the BASIC vpoke command, write a byte to the video RAM.
See the 'vpeek' command for more info about the VRAM address space.
}
proc vpoke {addr val} {
	debug write VRAM $addr $val
}

namespace export getcolor
namespace export setcolor
namespace export get_screen_mode
namespace export get_screen_mode_number
namespace export vdpreg
namespace export vdpregs
namespace export v9990regs
namespace export vpeek
namespace export vpoke
namespace export palette

} ;# namespace vdp

namespace import vdp::*
