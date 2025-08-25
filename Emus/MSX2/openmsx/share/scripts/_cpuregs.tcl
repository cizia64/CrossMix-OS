namespace eval cpuregs {

# reg command

set_help_text reg \
{Convenience procs to read or write Z80 registers.
Usage is similar to the builtin Tcl proc 'set'

 usage:
   reg <reg>            read from a Z80 register
   reg <reg> <value>    write to a Z80 register

     <reg> must be one of
        A   F   B   C   D   E   H   L
        A2  F2  B2  C2  D2  E3  H2  L2
        IXl IXh IYl IYh PCh PCl SPh SPl
        I   R   IM  IFF
        AF  BC  DE  HL
        AF2 BC2 DE2 HL2
        IX  IY  PC  SP

 examples:
   reg E           read register E
   reg HL          read register HL
   reg C 7         write 7 to register C
   reg AF 0x1234   write 0x12 to register A and 0x34 to F
}

variable regB [dict create \
	A    0    F    1    B    2    C    3 \
	D    4    E    5    H    6    L    7 \
	A2   8    F2   9    B2  10    C2  11 \
	D2  12    E2  13    H2  14    L2  15 \
	IXH 16    IXL 17    IYH 18    IYL 19 \
	PCH 20    PCL 21    SPH 22    SPL 23 \
	I   24    R   25    IM  26    IFF 27 ]

variable regW [dict create \
	AF   0    BC   2    DE   4    HL   6 \
	AF2  8    BC2 10    DE2 12    HL2 14 \
	IX  16    IY  18    PC  20    SP  22 ]

set_tabcompletion_proc reg [namespace code tab_reg] false

proc tab_reg {args} {
	variable regB
	variable regW
	concat [dict keys $regB] [dict keys $regW]
}

proc reg {name {val ""}} {
	variable regB
	variable regW

	set name [string toupper $name]
	if {[dict exists $regB $name]} {
		set i [dict get $regB $name]
		set single 1
	} elseif {[dict exists $regW $name]} {
		set i [dict get $regW $name]
		set single 0
	} else {
		error "Unknown Z80 register: $name"
	}
	set d "CPU regs"
	if {$val eq ""} {
		if {$single} {
			return [debug read $d $i]
		} else {
			return [expr {256 * [debug read $d $i] + [debug read $d [expr {$i + 1}]]}]
		}
	} else {
		if {$single} {
			debug write $d $i $val
		} else {
			debug write $d $i [expr {$val / 256}]
			debug write $d [expr {$i + 1}] [expr {$val & 255}]
		}
	}
}


# cpuregs command

set_help_text cpuregs "Gives an overview of all Z80 registers."

proc cw {reg} {format "%04X" [reg $reg]}
proc cb {reg} {format "%02X" [reg $reg]}

proc cpuregs {} {
	set result ""
	append result "AF =[cw AF ]  BC =[cw BC ]  DE =[cw DE ]  HL =[cw HL ]\n"
	append result "AF'=[cw AF2]  BC'=[cw BC2]  DE'=[cw DE2]  HL'=[cw HL2]\n"
	append result "IX =[cw IX ]  IY =[cw IY ]  PC =[cw PC ]  SP =[cw SP ]\n"
	append result "I  =[cb I  ]    R  =[cb R]    IM =[cb IM]    IFF=[cb IFF]"
	return $result
}


# get_active_cpu

set_help_text get_active_cpu "Returns the name of the active CPU ('z80' or 'r800')."

proc get_active_cpu {} {
	set result "z80"
	catch {
		# On non-turbor machines this debuggable doesn't exist
		if {([debug read "S1990 regs" 6] & 0x20) == 0} {
			set result "r800"
		}
	}
	return $result
}


namespace export reg
namespace export cpuregs
namespace export get_active_cpu

} ;# namespace cpuregs

namespace import cpuregs::*
