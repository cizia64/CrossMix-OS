# Binary format PSG logger
#
# (see http://www.msx.org/forumtopic6258.html for more context)
#
# Shiru wrote:
#
#  Is it possible to make output in standart binary *.psg format (used in
#  emulators like x128, very-very old version of fMSX, Z80Stealth and some other)?
#
#  Header:
#
#   +0 4 Signature #50 #53 #47 #1A ('PSG' and byte #1A)
#   +4 1 Version number
#   +5 1 Interrupts freq. (50/60)
#   +6 10 Unused
#
#  Note: only signature is necessary, many emulators just fill other bytes by zero.
#
#  Data stream:
#
#  #00..#FC - register number, followed by data byte (value for that register)
#  #FD - EOF (usually not used in real logs, and not all progs can handle it)
#  #FE - number of interrupts (followed byte with number of interrupts/4, usually not used)
#  #FF - single interrupt

namespace eval psg_log {

set_help_text psg_log \
{This script logs PSG registers 0 through 13 to a file as they are written,
seperated each frame.
The file format is the PSG format used in some emulators. More information
is here:  http://www.msx.org/forumtopic6258.html (and in the comments of
this script).

Usage:
   psg_log start <filename>  start logging PSG registers to <filename>
                             (default: log.psg)
   psg_log stop              stop logging PSG registers

Examples:
   psg_log start             start logging registers to default file log.psg
   psg_log start myfile.psg  start logging to file myfile.psg
   psg_log stop              stop logging PSG registers
}

set_tabcompletion_proc psg_log [namespace code tab_psg_log]

proc tab_psg_log { args } {
	if {[llength $args] == 2} {
		return "start stop"
	}
}

variable psg_log_file -1
variable psg_log_wp ""
variable psg_log_reg

proc psg_log { subcommand {filename "log.psg"} } {
	variable psg_log_file
	variable psg_log_wp
	if {$subcommand eq "start"} {
		if {$psg_log_file != -1} { close $psg_log_file }
		set psg_log_file [open $filename {WRONLY TRUNC CREAT}]
		fconfigure $psg_log_file -translation binary
		set header "0x50 0x53 0x47 0x1A 0 0 0 0 0 0 0 0 0 0 0 0"
		puts -nonewline $psg_log_file [binary format c16 $header]
		if {$psg_log_wp == ""} { set psg_log_wp [debug set_watchpoint write_io {0xa0 0xa1} 1 { psg_log::psg_log_write }] }
		after frame [namespace code do_psg_frame]
		return ""
	} elseif {$subcommand eq "stop"} {
		debug remove_watchpoint $psg_log_wp
		close $psg_log_file
		set psg_log_file -1
		set psg_log_wp ""
		return ""
	} else {
		error "bad option \"$subcommand\": must be start, stop"
	}
}

proc do_psg_frame {} {
	variable psg_log_file
	if {$psg_log_file == -1} return
	puts -nonewline $psg_log_file [binary format c 0xFF]
	after frame [namespace code do_psg_frame]
}

proc psg_log_write {} {
	variable psg_log_file
	variable psg_log_reg
	if {($::wp_last_address & 1) == 0} {
		set psg_log_reg $::wp_last_value
	} else {
		if {$psg_log_reg < 14} { puts -nonewline $psg_log_file [binary format c2 "$psg_log_reg $::wp_last_value"] }
	}
}

namespace export psg_log

} ;# namespace psg_log

namespace import psg_log::*
