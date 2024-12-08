namespace eval disasm {

# very common debug functions

proc peek {addr {m memory}} {
	debug read $m $addr
}
proc peek8 {addr {m memory}} {
	peek $addr $m
}
proc peek_u8 {addr {m memory}} {
	peek $addr $m
}
proc peek_s8 {addr {m memory}} {
	set b [peek $addr $m]
	expr {($b < 128) ? $b : ($b - 256)}
}
proc peek16 {addr {m memory}} {
	expr {[peek $addr $m] + 256 * [peek [expr {$addr + 1}] $m]}
}
proc peek16_LE {addr {m memory}} {
	peek16 $addr $m
}
proc peek16_BE {addr {m memory}} {
	expr {256 * [peek $addr $m] + [peek [expr {$addr + 1}] $m]}
}
proc peek_u16 {addr {m memory}} {
	peek16 $addr $m
}
proc peek_u16LE {addr {m memory}} {
	peek16 $addr $m
}
proc peek_u16BE {addr {m memory}} {
	peek16_BE $addr $m
}
proc peek_s16 {addr {m memory}} {
	set w [peek16 $addr $m]
	expr {($w < 32768) ? $w : ($w - 65536)}
}
proc peek_s16LE {addr {m memory}} {
	peek_s16 $addr $m
}
proc peek_s16BE {addr {m memory}} {
	set w [peek16_BE $addr $m]
	expr {($w < 32768) ? $w : ($w - 65536)}
}

set help_text_peek \
{Read a byte or word from the given memory location.
Optionally allows to specify a different 'debuggable' (default is 'memory').

usage:
  peek        <addr> [<mem>] Read unsigned 8-bit value from address
  peek8       <addr> [<mem>]      unsigned 8-bit
  peek_u8     <addr> [<mem>]      unsigned 8-bit
  peek_s8     <addr> [<mem>]        signed 8-bit
  peek16      <addr> [<mem>]      unsigned 16-bit little endian
  peek16_LE   <addr> [<mem>]      unsigned 16-bit little endian
  peek16_BE   <addr> [<mem>]      unsigned 16-bit big    endian
  peek_u16    <addr> [<mem>]      unsigned 16-bit little endian
  peek_u16_LE <addr> [<mem>]      unsigned 16-bit little endian
  peek_u16_BE <addr> [<mem>]      unsigned 16-bit big    endian
  peek_s16    <addr> [<mem>]        signed 16-bit little endian
  peek_s16_LE <addr> [<mem>]        signed 16-bit little endian
  peek_s16_BE <addr> [<mem>]        signed 16-bit big    endian
}
set_help_text peek        $help_text_peek
set_help_text peek8       $help_text_peek
set_help_text peek_u8     $help_text_peek
set_help_text peek_s8     $help_text_peek
set_help_text peek16      $help_text_peek
set_help_text peek16_LE   $help_text_peek
set_help_text peek16_BE   $help_text_peek
set_help_text peek_u16    $help_text_peek
set_help_text peek_u16_LE $help_text_peek
set_help_text peek_u16_BE $help_text_peek
set_help_text peek_s16    $help_text_peek
set_help_text peek_s16_LE $help_text_peek
set_help_text peek_s16_BE $help_text_peek


proc poke {addr val {m memory}} {
	debug write $m $addr $val
}
proc poke8 {addr val {m memory}} {
	poke $addr $val $m
}
proc poke16 {addr val {m memory}} {
	poke        $addr       [expr { $val       & 255}] $m
	poke [expr {$addr + 1}] [expr {($val >> 8) & 255}] $m
}
proc poke16_LE {addr val {m memory}} {
	poke16 $addr $val $m
}
proc poke16_BE {addr val {m memory}} {
	 poke        $addr       [expr {($val >> 8) & 255}] $m
	 poke [expr {$addr + 1}] [expr { $val       & 255}] $m
}
set help_text_poke \
{Write a byte or word to the given memory location.
Optionally allows to specify a different 'debuggable' (default is 'memory').

usage:
  poke      <addr> <val> [<mem>]   Write 8-bit value
  poke8     <addr> <val> [<mem>]         8-bit
  poke16    <addr> <val> [<mem>]        16-bit little endian
  poke16_LE <addr> <val> [<mem>]        16-bit little endian
  poke16_BE <addr> <val> [<mem>]        16-bit big    endian
}
set_help_text poke      $help_text_poke
set_help_text poke8     $help_text_poke
set_help_text poke16    $help_text_poke
set_help_text poke16_LE $help_text_poke
set_help_text poke16_BE $help_text_poke


# because of reverse we can now save replays to a file,
# poke-ing adds an entry into the replay file and therefore
# the file size can grow significantly. Therefor dpoke (poke
# if different or diffpoke) is introduced.
proc dpoke {addr val {m memory}} {
	if {[peek $addr $m] != $val} {poke $addr $val $m}
}


#
# disasm
#
set_help_text disasm \
{Disassemble z80 instructions

Usage:
  disasm                Disassemble 8 instr starting at the currect PC
  disasm <addr>         Disassemble 8 instr starting at address <adr>
  disasm <addr> <num>   Disassemble <num> instr starting at address <addr>
}
proc disasm {{address -1} {num 8}} {
	if {$address == -1} {set address [reg PC]}
	for {set i 0} {$i < int($num)} {incr i} {
		set l [debug disasm $address]
		append result [format "%04X  %s\n" $address [join $l]]
		set address [expr {($address + [llength $l] - 1) & 0xFFFF}]
	}
	return $result
}


#
# run_to
#
set_help_text run_to \
{Run to the specified address, if a breakpoint is reached earlier we stop
at that breakpoint.}
proc run_to {address} {
	set bp [debug set_bp $address]
	after break "debug remove_bp $bp"
	debug cont
}


#
# step_in
#
set_help_text step_in \
{Step in. Execute the next instruction, also go into subroutines.}
proc step_in {} {
	debug step
}
set_help_text step \
{Same as step_in.}
proc step {} {
	debug step
}


#
# step_out
#
set_help_text step_out \
{Step out of the current subroutine. In other words, execute till right after
the next 'ret' instruction (more if there were also extra 'call' instructions).
Note: simulation can be slow during execution of 'step_out', though for not
extremely large subroutines this is not a problem.}

variable step_out_bp1
variable step_out_bp2

proc step_out_is_ret {} {
	# ret        0xC9
	# ret <cc>   0xC0,0xC8,0xD0,..,0xF8
	# reti retn  0xED + 0x45,0x4D,0x55,..,0x7D
	set instr [peek16 [reg pc]]
	expr {(($instr & 0x00FF) == 0x00C9) ||
	      (($instr & 0x00C7) == 0x00C0) ||
	      (($instr & 0xC7FF) == 0x45ED)}
}
proc step_out_after_break {} {
	variable step_out_bp1
	variable step_out_bp2

	# also clean up when breaked, but not because of step_out
	catch {debug remove_condition $step_out_bp1}
	catch {debug remove_condition $step_out_bp2}
}
proc step_out_after_next {} {
	variable step_out_bp1
	variable step_out_bp2
	variable step_out_sp

	catch {debug remove_condition $step_out_bp2}
	if {[reg sp] > $step_out_sp} {
		catch {debug remove_condition $step_out_bp1}
		debug break
	}
}
proc step_out_after_ret {} {
	variable step_out_bp2

	catch {debug remove_condition $step_out_bp2}
	set step_out_bp2 [debug set_condition 1 [namespace code step_out_after_next]]
}
proc step_out {} {
	variable step_out_bp1
	variable step_out_bp2
	variable step_out_sp

	catch {debug remove_condition $step_out_bp1}
	catch {debug remove_condition $step_out_bp2}
	set step_out_sp [reg sp]
	set step_out_bp1 [debug set_condition {[disasm::step_out_is_ret]} [namespace code step_out_after_ret]]
	after break [namespace code step_out_after_break]
	debug cont
}


#
# step_over
#
set_help_text step_over \
{Step over. Execute the next instruction but don't step into subroutines.
Only 'call' or 'rst' instructions are stepped over. Note: 'push xx / jp nn'
sequences can in theory also be used as calls but these are not skipped
by this command.}
proc step_over {} {
	set address [reg PC]
	set l [debug disasm $address]
	set instr [lindex $l 0]
	if {[string match "call*" $instr] ||
	    [string match "rst*"  $instr] ||
	    [string match "ldir*" $instr] ||
	    [string match "cpir*" $instr] ||
	    [string match "inir*" $instr] ||
	    [string match "otir*" $instr] ||
	    [string match "lddr*" $instr] ||
	    [string match "cpdr*" $instr] ||
	    [string match "indr*" $instr] ||
	    [string match "otdr*" $instr] ||
	    [string match "halt*" $instr]} {
		run_to [expr {$address + [llength $l] - 1}]
	} else {
		debug step
	}
}


#
# step_back
#
set_help_text step_back \
{Step back. Go back in time till right before the last instruction was
executed. Note that this operation is relatively slow (compared to the other
step functions). Also the reverse feature must be enabled for this to work
(normally it's enabled by default).}
proc step_back {} {
	# In the past this proc was implemented totally different. It's worth
	# mentioning this old algorithm and explain why it wasn't good enough.
	# The old algorithm went like this:
	#  - take small steps back till we're not at the start instruction
	#    anymore (this works because 'reverse goto' only stops after
	#    emulating a full instruction)
	# The problem was that on R800 it could take _many_ (more than 80)
	# steps till the destination was reached.
	#
	# The current algorithm goes like this:
	#  - take a large step back
	#  - take small steps forward till we're back at the start
	#  - we now know where the previous instruction started, so go there
	#    (= take a small step back again)
	#
	# So the old algorithm takes (potentially) many backwards steps. While
	# the new algorithm takes exactly 2 backwards steps and (potentially)
	# many forward steps. In the current openMSX implementation, (small)
	# forward steps are orders of magnitude faster than backwards steps (an
	# optimization I added specifically for this use case). So the worst
	# execution time should now be much better.

	# 'z80' or 'r800'
	set cpu [get_active_cpu]

	# Get duration of one CPU cycle.
	set cycle_period [expr {1.0 / [machine_info ${cpu}_freq]}]

	# (Overestimation) for the maximum instruction length.
	#  On Z80 the slowest instruction is probably 'EX (SP),IX' (25 cycles).
	#  On R800 it's probably some I/O instruction to the VDP, followed by
	#  a memory refresh (up to 87(!) cycles). I added some extra cycles as
	#  a safety margin in case I forgot some extra penalty cycles (e.g.
	#  access to a device that inserts extra wait cycles).
	set max_instr_len [expr {(($cpu eq "z80") ? 35 : 100) * $cycle_period}]

	# Get time of the start instruction.
	set start [dict get [reverse status] "current"]

	# Go back till a moment that's certainly before the start instruction.
	reverse goback -novideo $max_instr_len
	set curr [dict get [reverse status] "current"]
	if {$curr >= $start} {
		error "Internal error: initial step-back was not big enough"
	}

	# Take small steps (forward) till we again reach the start instruction.
	while {1} {
		# Note that 'reverse goto' for a small forward step is
		# orders of magnitudes faster than a backwards 'reverse goto'.
		# The '-novideo' flag is required to not (temporarily
		# internally) step back a few video frames (so that immediately
		# after 'reverse goto' we have the correct video output).
		# Also note that this may take a bigger step forward than
		# requested: it will only stop after a complete instruction is
		# emulated.
		reverse goto -novideo [expr {$curr + $cycle_period}]
		set next [dict get [reverse status] "current"]
		if {$next > $start} {
			error "Internal error: overshot destination"
		}
		if {$next == $start} break
		set curr $next
	}

	# The previous step was the correct one, so go back there.
	# Note that (only here) we don't pass the '-novideo' flag
	reverse goto $curr
}


#
# skip one instruction
#
set_help_text skip_instruction \
{Skip the current instruction. In other words increase the program counter with the length of the current instruction.}
proc skip_instruction {} {
	set pc [reg pc]
	reg pc [expr {$pc + [llength [debug disasm $pc]] - 1}]
}

namespace export peek
namespace export peek8
namespace export peek_u8
namespace export peek_s8
namespace export peek16
namespace export peek16_LE
namespace export peek16_BE
namespace export peek_u16
namespace export peek_u16_LE
namespace export peek_u16_BE
namespace export peek_s16
namespace export peek_s16_LE
namespace export peek_s16_BE
namespace export poke
namespace export poke8
namespace export poke16
namespace export poke16_LE
namespace export poke16_BE
namespace export dpoke
namespace export disasm
namespace export run_to
namespace export step_over
namespace export step_back
namespace export step_out
namespace export step_in
namespace export step
namespace export skip_instruction

} ;# namespace disasm

namespace import disasm::*
