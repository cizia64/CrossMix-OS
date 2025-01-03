namespace eval reg_log {

set_help_text reg_log \
{Logs the contents (e.g. registers) of a given debuggable or replays such a log.
The state of the debuggable is saved to a log file every VDP frame. Note that
it does not take into account different VDP interrupt rates.

Usage:
   reg_log record <debuggable> [<filename>]   record <debuggable> to <filename>
                                              (default: <debuggable>.log)
   reg_log stop <debuggable>                  stop recording <debuggable>
   reg_log play <debuggable> <filename>       replay log in <filename>

Examples:
   reg_log record "PSG regs"        start logging PSG registers to
                                    "PSG regs.log"
   reg_log record memory mem.log    start logging memory to file mem.log
   reg_log stop "PSG regs"          stop logging "PSG regs"
   reg_log play "PSG regs" my.log   replay the log of "PSG regs" in my.log
}

set_tabcompletion_proc reg_log [namespace code tab_reg_log]
proc tab_reg_log {args} {
	switch [llength $args] {
		2 {return "record play stop"}
		3 {return [debug list]}
	}
}

variable log_file
variable data

proc reg_log {subcommand debuggable {filename ""}} {
	if {$filename eq ""} {set filename ${debuggable}.log}
	switch $subcommand {
		"record" {return [record $debuggable $filename]}
		"play"   {return [play $debuggable $filename]}
		"stop"   {return [stop $debuggable]}
		default  {error "bad option \"$subcommand\": must be record, play or stop"}
	}
}

proc check {debuggable} {
	if {$debuggable ni [debug list]} {
		error "No such debuggable: $debuggable"
	}
}

proc record {debuggable filename} {
	variable log_file
	check $debuggable
	stop $debuggable
	set log_file($debuggable) [open $filename {WRONLY TRUNC CREAT}]
	do_reg_record $debuggable
	return ""
}

proc play {debuggable filename} {
	variable data
	check $debuggable
	stop $debuggable
	set log_file [open $filename RDONLY]
	set data($debuggable) [split [read $log_file] \n]
	close $log_file
	do_reg_play $debuggable
	return ""
}

proc stop {debuggable} {
	variable log_file
	global file data
	if {[info exists log_file($debuggable)]} {
		close $log_file($debuggable)
		unset log_file($debuggable)
	}
	if {[info exists data($debuggable)]} {
		unset data($debuggable)
	}
	return ""
}

proc do_reg_record {debuggable} {
	variable log_file
	if {![info exists log_file($debuggable)]} return
	set size [debug size $debuggable]
	for {set i 0} {$i < $size} {incr i} {
		puts -nonewline $log_file($debuggable) "[debug read $debuggable $i] "
	}
	puts $log_file($debuggable) ""  ;#newline
	after frame [list reg_log::do_reg_record $debuggable]
}

proc do_reg_play {debuggable} {
	variable data
	if {![info exists data($debuggable)]} return
	set reg 0
	foreach val [lindex $data($debuggable) 0] {
		debug write $debuggable $reg $val
		incr reg
	}
	set data($debuggable) [lrange $data($debuggable) 1 end]
	if {[llength $data($debuggable)] > 0} {
		after frame [list reg_log::do_reg_play $debuggable]
	}
}

namespace export reg_log

} ;# namespace reg_log

namespace import reg_log::*
