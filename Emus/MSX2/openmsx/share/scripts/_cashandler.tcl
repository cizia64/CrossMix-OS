namespace eval cashandler {

set help_text_cas \
{-----------------------------------------------------------
  CAS-file tools 1.0 for openMSX Made By: NYYRIKKI & wouter_
------------------------------------------------------------
Usage:
 casload <file>             | Open CAS-file for load
 cassave <file>             | Open CAS-file for save
 caslist                    | Show loaded CAS-file content
 casrun [<file>] [<number>] | Automatically run program
 caspos <number>            | Select file to load from CAS
 caseject                   | Deactivate CAS-file support
}
set_help_text casload  $help_text_cas
set_help_text cassave  $help_text_cas
set_help_text caslist  $help_text_cas
set_help_text casrun   $help_text_cas
set_help_text caspos   $help_text_cas
set_help_text caseject $help_text_cas
set_tabcompletion_proc casload utils::file_completion
set_tabcompletion_proc cassave utils::file_completion
set_tabcompletion_proc casrun  utils::file_completion

variable fidr ""  ;# file id of opened read  file, "" if not active
variable fidw ""  ;# file id of opened write file, "" if not active
variable bptapion ;# tapion
variable bptapin  ;# tapin
variable bptapoon ;# tapoon
variable bptapout ;# tapout
variable bptapoof ;# tapoof
variable bphread  ;# h.read

variable casheader    [binary format H* "1FA6DEBACC137D74"]
variable casheaderSVI [binary format H* "555555555555555555555555555555557F"]
variable casbios    [dict create r [list 0x00E2 tapion 0x00E5 tapin  0x00E8 tapiof] \
                                 w [list 0x00EB tapoon 0x00EE tapout 0x00F1 tapoof]]
variable casbiosSVI [dict create r [list 0x006A tapion 0x006D tapin  0x0070 tapiof] \
                                 w [list 0x0073 tapoon 0x0076 tapout 0x0079 tapoof]]

proc casload {filename} {
	casopen $filename "r"
	return "Cassette inserted, overriding normal openMSX cassette load routines."
}
proc cassave {filename} {
	casopen $filename "w"
	return "Cassette inserted, overriding normal openMSX cassette save routines."
}
proc caseject {} {
	casclose "r"
	casclose "w"
	return "Cassette ejected, normal openMSX cassette routines in use."
}

proc casopen {filename rw} {
	# Possibly close previous file.
	casclose $rw

	# Open file.
	variable fid${rw}
	set fid${rw} [open $filename $rw]
	fconfigure [set fid${rw}] -translation binary -encoding binary

	# Install BIOS handlers.
	variable casbios
	variable casbiosSVI
	if {[machine_info type] eq "SVI"} {
		set bios $casbiosSVI
	} else {
		set bios $casbios
	}
	foreach {addr func} [dict get $bios $rw] {
		variable bp${func}
		if {[machine_info type] eq "SVI"} {
			set slotspec "3 X X"
		} else {
			set slotspec "0 0"
		}
		set bp${func} [debug set_bp [peek16 $addr "slotted memory"] "\[pc_in_slot {*}${slotspec}\]" [namespace code $func]]
	}
}

proc casclose {rw} {
	# Was active?
	variable fid${rw}
	if {[set fid${rw}] eq ""} return

	# Uninstall BIOS handlers.
	variable casbios
	variable casbiosSVI
	if {[machine_info type] eq "SVI"} {
		set bios $casbiosSVI
	} else {
		set bios $casbios
	}
	foreach {addr func} [dict get $bios $rw] {
		variable bp${func}
		debug remove_bp [set bp${func}]
	}

	if {$rw eq "r"} {
		# In case of read (possibly) also remove bphread.
		variable bphread
		catch {debug remove_bp $bphread} ;# often not set, so catch error
	} else {
	        # In case of write align end of file in order to make combine with other CAS-files easy.
		set align [expr {[tell $fidw] & 7}]
		if {$align} {puts -nonewline $fidw [string repeat \x0 [expr {8 - $align}]]}
	}

	# Close file and deactivate.
	close [set fid${rw}]
	set fid${rw} ""
}

proc tapion {} {
	# TAPION
	# Address  : #00E1
	# Function : Reads the header block after turning the cassette motor on
	# Output   : C-flag set if failed
	# Registers: All
	if {[machine_info type] eq "SVI"} {
		seekheader
	} else {
		reg F [expr {([seekheader] == -1) ? 0x01 : 0x40}] ;# set carry flag if header not found
	}
	ret
}

proc tapin {} {
	# TAPIN
	# Address  : #00E4
	# Function : Read data from the tape
	# Output   : A  - read value
	#           C-flag set if failed
	# Registers: All
	variable fidr
	if {[binary scan [read $fidr 1] cu val]} {
		reg A $val
		reg F 0x40 ;# ok, clear carry flag
	} else {
		reg F 1 ;# end-of-file reached, set carry flag
	}
	ret
}

proc tapiof {} {
        #TAPIOF
        #Address  : #00E7
        #Function : Stops reading from tape
        #Registers: None
	ret
}

proc tapoon {} {
        #TAPOON
        #Address  : #00EA
        #Function : Turns on the cassette motor and writes the header
        #Input    : A  - #00 short header
        #            not #00 long header
        #Output   : C-flag set if failed
        #Registers: All
	if {[catch {
		variable fidw
		variable casheader
		variable casheaderSVI
		if {[machine_info type] eq "SVI"} {
			set header $casheaderSVI
		} else {
			set align [expr {[tell $fidw] & 7}]
			if {$align} {puts -nonewline $fidw [string repeat \x0 [expr {8 - $align}]]}
			set header $casheader
		}
		puts -nonewline $fidw $header
		if {[machine_info type] ne "SVI"} {
			reg F 0x40 ;# ok, clear carry flag
		}
	}]} {
		if {[machine_info type] ne "SVI"} {
			reg F 1 ;# write error, set carry flag
		}
	}
	ret
}

proc tapout {} {
        #TAPOUT
        #Address  : #00ED
        #Function : Writes data on the tape
        #Input    : A  - data to write
        #Output   : C-flag set if failed
        #Registers: All
	if {[catch {
		variable fidw
		puts -nonewline $fidw [binary format c* [reg A]]
		reg F 0x40 ;# all went fine, clear carry flag
	}]} {
		reg F 1 ;# write error, set carry flag
	}
	ret
}

proc tapoof {} {
        #TAPOOF
        #Address  : #00F0
        #Function : Stops writing on the tape
        #Registers: None
	ret
}

proc ret {} {
	reg PC [peek16 [reg SP]]
	reg SP [expr {[reg SP] + 2}]
}

proc seekheader {} {
	variable fidr
	if {[machine_info type] ne "SVI"} {
		# Skip till 8-bytes aligned.
		set align [expr {[tell $fidr] & 7}]
		if {$align} {read $fidr [expr {8 - $align}]}
	}

	# Search header.
	if {[machine_info type] eq "SVI"} {
		while {true} {
			variable casheaderSVI
			set pos [tell $fidr]
			if {[eof $fidr]} {break}
			if {[read $fidr 17] eq $casheaderSVI} {break}
			seek $fidr $pos start
			read $fidr 1
		}

		# Return position of header in cas file, or -1 if not found.
		expr {[eof $fidr] ? -1 : $pos}
	} else {
		variable casheader
		while {![eof $fidr] && [read $fidr 8] ne $casheader} {}

		# Return position of header in cas file, or -1 if not found.
		expr {[eof $fidr] ? -1 : ([tell $fidr] - 8)}
	}
}

proc readheader {} {
	# Read (first) type-id byte.
	variable fidr
	set byte [read $fidr 1]
	if {![binary scan $byte cu val]} {return -1}

	# This must be one of 0xEA 0xD0 0xD3.
	set type [lsearch -exact -integer [list 0xEA 0xD0 0xD3] $val]
	if {$type == -1} {return -1}

	# And it must repeat 9 more times.
	for {set i 0} {$i < 9} {incr i} {
		if {[read $fidr 1] ne $byte} {return -1}
	}
	return $type
}

proc checkactive {} {
	variable fidr
	if {$fidr eq ""} {error "No cas file loaded, use 'casload <filename>'."}
}

proc caslist {} {
	checkactive

	set    result "Position: Type: Name:    Offset:\n"
	append result "--------------------------------\n"

	variable fidr
	set oldpos [tell $fidr]
	seek $fidr 0
	set i 0
	while {![eof $fidr]} {
		set headerpos [seekheader]
		set type [readheader]
		if {$type == -1} continue
		append result [expr {($headerpos < $oldpos) ? "| " : "  "}]
		append result [format %5d [incr i]] " : "
		append result [lindex "TXT BIN BAS" $type] " : "
		append result [read $fidr 6] " : "
		append result $headerpos "\n"
	}
	seek $fidr $oldpos
	return $result
}

proc caspos {{position 1}} {
	checkactive
	lassign [seekpos $position] headerpos type
	return "Cassette header put to offset: $headerpos"
}

# Seek to the start of the n-th header and return both the
# file-offset and the type of this header.
proc seekpos {position} {
	if {![string is integer $position] || ($position <= 0)} {
		error "Expected a strict positive integer, but got $position."
	}

	variable fidr
	seek $fidr 0
	set i 0
	while {$i != $position} {
		set headerpos [seekheader]
		set type [readheader]
		if {$type != -1} {incr i}
		if {[eof $fidr]} {error "No entry $position in this cas file."}
	}
	seek $fidr $headerpos
	list $headerpos $type
}

proc casrun {{filename 1} {position 1}} {
	variable fidr
	variable bphread
	if {[string is integer $filename] && ($fidr ne "")} {
		# First argument is actually a position instead of a filename,
		# only works when there already is a cas file loaded.
		set position $filename
		catch {debug remove_bp $bphread} ;# often not set, so catch error
	} else {
		# Interpret 1st argument as a filename and load it.
		casload $filename
	}
	lassign [seekpos $position] headerpos type

	catch {carta eject}
	catch {cartb eject} ;# there are machines without slot-B
	reset
	set ::power on
	if {[machine_info type] eq "SVI"} {
		set bpaddr 0xfe94
	} else {
		set bpaddr 0xff07
		keymatrixdown 6 1 ;# press SHIFT
	}
	set bphread [debug set_bp ${bpaddr} {} [namespace code "typeload $type"]]
	return ""
}

proc typeload {type} {
	variable bphread
	catch {debug remove_bp $bphread} ;# often not set, so catch error
	if {[machine_info type] eq "SVI"} {
		set keybuf 0xfd8b
		set getpnt 0xfa1c
		set putpnt 0xfa1a
	} else {
		keymatrixup 6 1 ;# release SHIFT
		set keybuf 0xfbf0
		set getpnt 0xf3fa
		set putpnt 0xf3f8
	}

	set cmd [lindex [list "RUN\"CAS:\r" "BLOAD\"CAS:\",R\r" "CLOAD\rRUN\r"] $type]
	debug write_block memory $keybuf $cmd
	poke16 ${getpnt} $keybuf
	poke16 ${putpnt} [expr {$keybuf + [string length $cmd]}]
}

######################################################
proc tapedeck {args} {
	set isCas [expr {[string toupper [file extension [lindex $args end]]] eq ".CAS"}]
	if {$isCas} {

		switch [lindex $args 0] {
			eject         {caseject}
			rewind        {caspos 1}
			motorcontrol  {}
			play          {}
			record        {}
			new           {cassave [lindex $args 1]}
			insert        {casload [lindex $args 1]}
			getpos        {}
			getlength     {}
			""            {}
			default       {
				casload {*}$args
				# for SVI we can't use the trick below, so use typeload
				if {[expr {[machine_info type] eq "SVI" && $::autoruncassettes}]} {
					lassign [seekpos 1] headerpos type
					typeload $type
				}
			}
		}
	} else {
		caseject
	}

	if {[expr {[machine_info type] ne "SVI" || !$isCas}]} {
		# also insert the file in the normal openMSX cassetteplayer
		# to trigger the behaviour that happens when we do (e.g. autoload)
		# and of course to get normal behaviour for non-CAS files
		return [uplevel 1 [list interp invokehidden {} -global cassetteplayer] $args]
	}
}

######################################################

namespace export casload cassave caslist casrun caspos caseject

} ;# namespace cashandler

namespace import cashandler::*
