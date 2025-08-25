set_help_text save_msx_screen \
{Lookup the screen mode and save the current screen to a MSX compatible binary
file. This file can for example be loaded in MSX-BASIC using the BLOAD command.

This script was originally developed by NYYRIKKI, see also this forum thread:
http://www.msx.org/forum/msx-talk/general-discussion/taking-sc5-snapshot-games
}

proc save_msx_screen {basename} {
	# Gives an error in case of an invalid screen mode.
	set mode_num [get_screen_mode_number]

	# Read VDP registers (only once)
	foreach n {2 3 4 5 6 9 10 11 23} {
		set R$n [vdpreg $n]
	}

	set name_base        [expr {($R2      ) * 0x400}]
	set name_base_80     [expr {($R2 & 252) * 0x400}]
	set name_base_bitmap [expr {($R2 &  96) * 0x400}]
	set color_base       [expr {($R3      ) * 0x40 + $R10 * 0x4000}]
	set color_base_2     [expr {($R3 & 128) * 0x40 + $R10 * 0x4000}]
	set pattern_base     [expr {($R4      ) * 0x800}]
	set pattern_base_2   [expr {($R4 &  60) * 0x800}]
	set spr_att_base     [expr {($R5      ) * 0x80 + $R11 * 0x8000}]
	set spr_att_base_2   [expr {($R5 & 252) * 0x80 + $R11 * 0x8000 - 0x200}]
	set spr_pat_base     [expr {($R6      ) * 0x800}]
	set interlace        [expr {(($R9 & 12) == 12) && ($R2 & (($mode_num < 7) ? 16 : 32))}]

	set sections [list]
	set sections2 [list]
	switch [get_screen_mode] {
	"TEXT40" {
		lappend sections "VRAM" $name_base 0x400                    ;# BG Map
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$name_base + 0x420}] 0x3E0   ;# Fill (BG Map)
		lappend sections "VRAM" $pattern_base 0x800                 ;# BG Tiles
	}
	"TEXT80" {
		lappend sections "VRAM" $name_base_80 0x800                 ;# BG Map
		lappend sections "VRAM" $color_base 0x700                   ;# Blink
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$name_base_80 + 0xF20}] 0xE0 ;# Fill (BG Map)
		lappend sections "VRAM" $pattern_base 0x800                 ;# BG Tiles
	}
	"1" {
		lappend sections "VRAM" $pattern_base 0x1800                ;# BG Tiles
		lappend sections "VRAM" $name_base 0x300                    ;# BG Map
		lappend sections "VRAM" $spr_att_base 0x500                 ;# OBJ Attributes
		lappend sections "VRAM" $color_base 0x20                    ;# BG Colors
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$color_base + 0x40}] 0x17C0  ;# Fill (BG Colors)
		lappend sections "VRAM" $spr_pat_base 0x800                 ;# OBJ Tiles
	}
	"2" {
		lappend sections "VRAM" $pattern_base_2 0x1800              ;# BG Tiles
		lappend sections "VRAM" $name_base 0x300                    ;# BG Map
		lappend sections "VRAM" $spr_att_base 0x80                  ;# OBJ Attributes
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$spr_att_base + 0xA0}] 0x460 ;# Fill (OBJ Attributes)
		lappend sections "VRAM" $color_base_2 0x1800                ;# BG Colors
		lappend sections "VRAM" $spr_pat_base 0x800                 ;# OBJ Tiles
	}
	"3" {
		lappend sections "VRAM" $pattern_base 0x800                 ;# BG Tiles
		lappend sections "VRAM" $name_base 0x1300                   ;# BG Map
		lappend sections "VRAM" $spr_att_base 0x520                 ;# OBJ Attributes
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$spr_att_base + 0x540}] 0x17C0 ;# Fill (OBJ Attributes)
		lappend sections "VRAM" $spr_pat_base 0x800                 ;# OBJ Tiles
	}
	"4" {
		lappend sections "VRAM" $pattern_base_2 0x1800              ;# BG Tiles
		lappend sections "VRAM" $name_base 0x380                    ;# BG Map
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$name_base + 0x3A0}] 0x60    ;# Fill (BG Map)
		lappend sections "VRAM" $spr_att_base_2 0x400               ;# OBJ Attributes
		lappend sections "VRAM" $color_base_2 0x1800                ;# BG Colors
		lappend sections "VRAM" $spr_pat_base 0x800                 ;# OBJ Tiles
	}
	"5" - "6" {
		set lines1 [expr {$R23 > 24 ? 256 - $R23 : 232}]            ;# Store 232 lines, even
		set lines2 [expr {232 - $lines1}]                           ;# though only 212 are visible
		set base2 [expr {$name_base_bitmap - (0x8000 * $interlace)}]
		set base1 [expr {$base2 + $R23 * 128}]
		lappend sections "VRAM" $base1 [expr {$lines1 * 128}]       ;# Bitmap (part 1)
		lappend sections "VRAM" $base2 [expr {$lines2 * 128}]       ;# Bitmap (part 2)
		lappend sections "VRAM" $spr_att_base_2 0x280               ;# Sprite colors + attributes
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		lappend sections "VRAM" [expr {$name_base_bitmap - (0x8000 * $interlace) + 0x76A0}] 0x160 ;# Fill (Bitmap)
		lappend sections "VRAM" $spr_pat_base 0x800                 ;# Sprite character patterns
		if {$interlace} {
			lappend sections2 "VRAM" [expr {$base1 + 0x8000}] [expr {$lines1 * 128}]   ;# Bitmap (part 1)
			lappend sections2 "VRAM" [expr {$base2 + 0x8000}] [expr {$lines2 * 128}]   ;# Bitmap (part 2)
			lappend sections2 "VRAM" [expr {$spr_att_base_2 + 0x8000}] 0x280           ;# Sprite colors + attributes
			lappend sections2 "VDP palette" 0 0x20                                     ;# Palette
			lappend sections2 "VRAM" [expr {$name_base_bitmap + 0x76A0}] 0x160         ;# Fill (Bitmap)
			lappend sections2 "VRAM" [expr {$spr_pat_base + 0x8000}] 0x800             ;# Sprite character patterns
		}
	}
	"7" - "8" - "11" - "12" {
		set lines1 [expr {$R23 > 16 ? 256 - $R23 : 240}]            ;# Store 240 lines, even
		set lines2 [expr {240 - $lines1}]                           ;# though only 212 are visible
		set base2 [expr {($name_base_bitmap * 2) & 0x10000 - (0x10000 * $interlace)}]
		set base1 [expr {$base2 + $R23 * 256}]
		lappend sections "VRAM" $base1 [expr {$lines1 * 256}]       ;# Bitmap (part 1)
		lappend sections "VRAM" $base2 [expr {$lines2 * 256}]       ;# Bitmap (part 2)
		lappend sections "VRAM" $spr_pat_base 0x800                 ;# Sprite character patterns
		lappend sections "VRAM" $spr_att_base_2 0x280               ;# Sprite colors + attributes
		lappend sections "VDP palette" 0 0x20                       ;# Palette
		if {$interlace} {
			lappend sections2 "VRAM" [expr {$base1 + 0x10000}] [expr {$lines1 * 256}]  ;# Bitmap (part 1)
			lappend sections2 "VRAM" [expr {$base2 + 0x10000}] [expr {$lines2 * 256}]  ;# Bitmap (part 2)
			lappend sections2 "VRAM" [expr {$spr_pat_base + 0x10000}] 0x800            ;# Sprite character patterns
			lappend sections2 "VRAM" [expr {$spr_att_base_2 + 0x10000}] 0x280          ;# Sprite colors + attributes
			lappend sections2 "VDP palette" 0 0x20                                     ;# Palette
		}
	}}

	set directory [file normalize $::env(OPENMSX_USER_DATA)/../screenshots]

	set result ""
	foreach {ext sec} [list ".SC" $sections ".S1" $sections2] {
		if {[llength $sec] == 0} break

		# Open file with correct extension
		set fname [file join $directory [format "%s%s%X" $basename $ext $mode_num]]
		set out [open $fname w]
		fconfigure $out -translation binary

		# write header
		set end_addr -1
		foreach {type addr size} $sec {
			incr end_addr $size
		}
		set header [list 0xFE 0 0 [expr {$end_addr & 255}] [expr {$end_addr / 256}] 0 0]
		puts -nonewline $out [binary format c* $header]

		# write data sections
		foreach {type addr size} $sec {
			puts -nonewline $out [debug read_block $type $addr $size]
		}
		close $out

		append result "Screen written to $fname\n"
	}
	return $result
}
