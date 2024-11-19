# Return the content of the MSX screen as a string (text-modes only)

set_help_text get_screen \
{Returns the content of the MSX screen as a string (only works for text-modes).
}

proc get_screen {} {
	set mode [get_screen_mode_number]
	switch -- $mode {
		0 {
			set addr 0
			set width [expr {([debug read "VDP regs" 0] & 0x04) ? 80 : 40}]
		}
		1 {
			set addr 6144
			set width 32
		}
		default {
			error "Screen mode $mode not supported"
		}
	}

	# scrape screen and build string
	set screen ""
	for {set y 0} {$y < 24} {incr y} {
		set line ""
		for {set x 0} {$x < $width} {incr x} {
			set char [vpeek $addr]
			if {$char == 255 && [machine_info type] eq "MSX"} {
				set char [peek 0xFBCC]
			} elseif {$char == 191 && [machine_info type] eq "SVI"} {
				set char [peek 0xFD67]
			}
			append line [format %c $char]
			incr addr
		}
		append screen [string trim $line] "\n"
	}
	return [string trim $screen]
}

#***********************************************
#* Basic Reader
#*
#* A special thanks to Vincent van Dam for
#* giving me permission to translate his
#* script into Tcl
#***********************************************

set_help_text listing \
{Interpret the content of the memory as a BASIC program and return the
equivalent output of the BASIC LIST command. (May not be terribly useful, but
it does show the power of openMSX scripts ;-) You can add an optional start
address for the decoding; by default it's what the system variable TXTTAB says.
}

proc listing {{startaddr "default"}} {

	# TODO: reduce duplication, difference seems only in last couple of
	# lines

	set tokens1MSX [list \
		"" "END" "FOR" "NEXT" "DATA" "INPUT" "DIM" "READ" "LET" \
		"GOTO" "RUN" "IF" "RESTORE" "GOSUB" "RETURN" "REM" "STOP" \
		"PRINT" "CLEAR" "LIST" "NEW" "ON" "WAIT" "DEF" "POKE" "CONT" \
		"CSAVE" "CLOAD" "OUT" "LPRINT" "LLIST" "CLS" "WIDTH" "ELSE" \
		"TRON" "TROFF" "SWAP" "ERASE" "ERROR" "RESUME" "DELETE" \
		"AUTO" "RENUM" "DEFSTR" "DEFINT" "DEFSNG" "DEFDBL" "LINE" \
		"OPEN" "FIELD" "GET" "PUT" "CLOSE" "LOAD" "MERGE" "FILES" \
		"LSET" "RSET" "SAVE" "LFILES" "CIRCLE" "COLOR" "DRAW" "PAINT" \
		"BEEP" "PLAY" "PSET" "PRESET" "SOUND" "SCREEN" "VPOKE" \
		"SPRITE" "VDP" "BASE" "CALL" "TIME" "KEY" "MAX" "MOTOR" \
		"BLOAD" "BSAVE" "DSKO$" "SET" "NAME" "KILL" "IPL" "COPY" "CMD" \
		"LOCATE" "TO" "THEN" "TAB(" "STEP" "USR" "FN" "SPC(" "NOT" \
		"ERL" "ERR" "STRING$" "USING" "INSTR" "'" "VARPTR" "CSRLIN" \
		"ATTR$" "DSKI$" "OFF" "INKEY$" "POINT" ">" "=" "<" "+" "-" "*" \
		"/" "^" "AND" "OR" "XOR" "EQV" "IMP" "MOD" "\\" "\n" "" \
		"\0x127"]

	set tokens1SVI [list \
		"" "END" "FOR" "NEXT" "DATA" "INPUT" "DIM" "READ" "LET" \
		"GOTO" "RUN" "IF" "RESTORE" "GOSUB" "RETURN" "REM" "STOP" \
		"PRINT" "CLEAR" "LIST" "NEW" "ON" "WAIT" "DEF" "POKE" "CONT" \
		"CSAVE" "CLOAD" "OUT" "LPRINT" "LLIST" "CLS" "WIDTH" "ELSE" \
		"TRON" "TROFF" "SWAP" "ERASE" "ERROR" "RESUME" "DELETE" \
		"AUTO" "RENUM" "DEFSTR" "DEFINT" "DEFSNG" "DEFDBL" "LINE" \
		"OPEN" "FIELD" "GET" "PUT" "CLOSE" "LOAD" "MERGE" "FILES" \
		"LSET" "RSET" "SAVE" "LFILES" "CIRCLE" "COLOR" "DRAW" "PAINT" \
		"BEEP" "PLAY" "PSET" "PRESET" "SOUND" "SCREEN" "VPOKE" \
		"KEY" "CLICK" "SWITCH" "MAX" "MON" "MOTOR" "BLOAD" "BSAVE" \
		"MDM" "DIAL" "DSKO$" "SET" "NAME" "KILL" "IPL" "COPY" "CMD" \
		"LOCATE" "TO" "THEN" "TAB(" "STEP" "USR" "FN" "SPC(" "NOT" \
		"ERL" "ERR" "STRING$" "USING" "INSTR" "'" "VARPTR" "CSRLIN" \
		"ATTR$" "DSKI$" "OFF" "INKEY$" "POINT" "SPRITE" "TIME" ">" \
		"=" "<" "+" "-" "*" "/" "^" "AND" "OR" "XOR" "EQV" "IMP" \
		"MOD" "\\" "\0x127"]

	set tokens2 [list \
		"" "LEFT$" "RIGHT$" "MID$" "SGN" "INT" "ABS" "SQR" "RND" "SIN" \
		"LOG" "EXP" "COS" "TAN" "ATN" "FRE" "INP" "POS" "LEN" "STR$" \
		"VAL" "ASC" "CHR$" "PEEK" "VPEEK" "SPACE$" "OCT$" "HEX$" \
		"LPOS" "BIN$" "CINT" "CSNG" "CDBL" "FIX" "STICK" "STRIG" "PDL" \
		"PAD" "DSKF" "FPOS" "CVI" "CVS" "CVD" "EOF" "LOC" "LOF" "MKI$" \
		"MKS$" "MKD$" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" \
		"" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" \
		"" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" \
		"" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""]

	if {[machine_info type] eq "SVI"} {
		set TXTTAB 0xF54A
		set tokens1 $tokens1SVI
	} else {
		set TXTTAB 0xF676
		set tokens1 $tokens1MSX
	}

	if {$startaddr eq "default"} {
		set startaddr [peek16 $TXTTAB]
	}

	# Loop over all lines
	set listing ""
	for {set addr $startaddr} {[peek16 $addr] != 0} {} {
		append listing [format "0x%x > " $addr]
		incr addr 2
		append listing "[peek16 $addr] "
		incr addr 2
		set inquotes false
		set inrem false
		# Loop over tokens in one line
		while {true} {
			set token [peek $addr]; incr addr
			set t [format "%c" $token]
			if {$token == 0x0} {
				set t ""
				break
			} elseif {$token == 0x22} {
				set inquotes [expr !$inquotes]
			}
			if {!$inquotes && !$inrem} {
				if {0x80 < $token && $token < 0xFF} {
					if {$token == 0x8F} {
						if {[peek $addr] == 0xE6} {
							set t "'"
							incr addr
						} else {
							set t "REM"
						}
						set inrem true
					} else {
						set t [lindex $tokens1 [expr {$token - 0x80}]]
					}
				} elseif {$token == 0xFF} {
					set t [lindex $tokens2 [expr {[peek $addr] - 0x80}]]
					incr addr
				} elseif {$token == 0x3a} {
					if {[peek $addr] == 0xA1 || ([peek $addr] == 0x8F && [peek [expr {$addr + 1}]] == 0xE6)} {
						set t ""
					}
				} elseif {$token == 0x0B} {
					set t [format "&O%o" [peek16 $addr]]
					incr addr 2
				} elseif {$token == 0x0C} {
					set t [format "&H%X" [peek16 $addr]]
					incr addr 2
				} elseif {$token == 0x0D} {
					# line number (stored as address)
					set t [format "%d" [peek16 [expr {[peek16 $addr] + 3}]]]
					incr addr 2
				} elseif {$token == 0x0E} {
					set t [format "%d" [peek16 $addr]]
					incr addr 2
				} elseif {$token == 0x0F} {
					set t [format "%d" [peek $addr]]
					incr addr
				} elseif {$token == 0x1C} {
					set t [format "%d" [peek16 $addr]]
					incr addr 2
				} elseif {$token == 0x1D} {
					set exp [peek $addr]
					incr addr
					set t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					set exp "E[expr {($exp & 0x7F) - 70}]"
					set t [make_msx_single $t$exp]
				} elseif {$token == 0x1F} {
					set exp [peek $addr]
					incr addr
					set t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					append t [format "%02x" [peek $addr]]
					incr addr
					set exp "E[expr {($exp & 0x7F) - 78}]"
					set t [make_msx_double $t$exp]
				} elseif {0x11 <= $token && $token <= 0x1A} {
					set t [expr {$token - 0x11}]
				}
			}
			append listing $t
		}
		append listing "\n"
	}
	return $listing
}

proc make_msx_double {num} {
	if {[string toupper $num] ne $num} {
		error "Invalid BASIC program"
	}
	set n [format "% .14E" $num]
	set ee [string range $n 18 20]
	set e [scan $ee %d]
	if {$e <-2 && $e >-5} {
		set n [format "%.14G" [string range $n 0 16]]E$ee
	} else {
		set n [format "%.14G" $num]
	}
	if {[string range $n 0 1] eq "0."} {\
		set n [string range $n 1 100]
	}
	if {![string match *E* $n]} {
		append n "#"
	}
	return $n
}

proc make_msx_single {num} {
	if {[string toupper $num] ne $num} {
		error "Invalid BASIC program"
	}
	set n [format "% .6E" $num]
	set ee [string range $n 10 12]
	set e [scan $ee %d ]
	if {$e <-2 && $e >-5} {
		set n [format "%.6G" [string range $n 0 8]]E$ee
	} else {
		set n [format "%.6G" $num]
	}
	if {[string range $n 0 1] eq "0."} {
		set n [string range $n 1 100]
	}
	if {$n >32767 && ![string match *.* $n]} {
		append n "!"
	}
	return $n
}

set_help_text get_color_count \
"Gives some statistics on the used colors of the currently visible screen. Does not take into account sprites, screen splits and other trickery.

Options:
    -sort <field>, where <field> is either 'color' (default) or 'amount'
    -reverse, to reverse the sorting order
    -all, to also include colors that have a count of zero
"
proc get_color_count {args} {
	set result ""

	set sortindex 0
	set sortorder "-increasing"
	set showall false

	# parse options
	while {1} {
		switch -- [lindex $args 0] {
		"" break
		"-sort" {
			set sortfield [lindex $args 1]
			if {$sortfield eq "color"} {
				set sortindex 0
			} elseif {$sortfield eq "amount"} {
				set sortindex 1
			} else {
				error "Unsupported sort field: $sortfield"
			}
			set args [lrange $args 2 end]
		}
		"-reverse" {
			set sortorder "-decreasing"
			set args [lrange $args 1 end]
		}
		"-all" {
			set showall true
			set args [lrange $args 1 end]
		}
		"default" {
			error "Invalid option: [lindex $args 0]"
		}
		}
	}

	set mode [get_screen_mode_number]
	switch -- $mode {
		5 {
			set nofbytes_per_line 128
			set nofpixels_per_byte 2
			set page_size [expr {32 * 1024}]
		}
		6 {
			set nofbytes_per_line 128
			set nofpixels_per_byte 4
			set page_size [expr {32 * 1024}]
		}
		7 {
			set nofbytes_per_line 256
			set nofpixels_per_byte 2
			set page_size [expr {64 * 1024}]
		}
		8 {
			set nofbytes_per_line 256
			set nofpixels_per_byte 1
			set page_size [expr {64 * 1024}]
		}
		default {
			error "Screen mode $mode not supported (yet)"
		}
	}
	set page [expr {([debug read "VDP regs" 2] & 96) >> 5}]
	set noflines [expr {([debug read "VDP regs" 9] & 128) ? 212 : 192}]
	set bpp [expr {8 / $nofpixels_per_byte}]
	set nrcolors [expr {1 << $bpp}]
	append result "Counting pixels of screen $mode, page $page with $noflines lines...\n"

	# get bytes into large list
	set offset [expr {$page_size * $page}]
	set nrbytes [expr {$noflines * $nofbytes_per_line}]
	binary scan [debug read_block VRAM $offset $nrbytes] c* myvram

	# analyze pixels
	set pixelstats [dict create]
	for {set p 0} {$p < $nrcolors} {incr p} {
		dict set pixelstats $p 0
	}
	set mask [expr {$nrcolors - 1}]
	foreach byte $myvram {
		for {set pixel 0} {$pixel < $nofpixels_per_byte} {incr pixel} {
			set color [expr {($byte >> ($pixel * $bpp)) & $mask}]
			dict incr pixelstats $color
		}
	}
	# convert to list
	set pixelstatlist [list]
	dict for {key val} $pixelstats {
		if {$showall || ($val != 0)} {
			lappend pixelstatlist [list $key $val]
		}
	}
	set pixelstatlistsorted [lsort -integer $sortorder -index $sortindex $pixelstatlist]
	# print results
	set number 0
	set colorwidth [expr {($mode == 8) ? 3 : 2}]
	set palette ""
	foreach pixelinfo $pixelstatlistsorted {
		incr number
		lassign $pixelinfo color amount
		if {$mode != 8} {
			set palette " ([getcolor $color])"
		}
		append result [format "%${colorwidth}d: color %${colorwidth}d$palette: amount: %6d\n" $number $color $amount]
	}
	return $result
}

variable tron_bp

proc toggle_tron {} {
	variable tron_bp

	if {[osd exists tron]} {
		osd destroy tron
		debug remove_bp $tron_bp
		return "Off"
	}

	set tron_bp [debug set_bp 0xFF43 {} {update_tron}]

	osd create rectangle tron \
		-x 269 -y 220 -h 7 -w 42 -scaled true \
		-borderrgba 0x00000040 -bordersize 0.5
	osd create text tron.text -x 3 -y 1 -size 4 -rgba 0xffffffff
	return "On"
}

proc update_tron {} {
	if {![osd exists tron]} return
	set tron ""
	if {[peek16 0xF41C] != 0xFFFF} {
		set tron "Line: [peek16 0xF41C]"
	}
	osd configure tron.text -text ${tron}
}
