namespace eval vdp_busy {

variable last_executing 0
variable executing_time 0
variable sample_time 0
variable display_time 0
variable bp_id
variable after_id

proc reset {} {
	variable last_executing 0
	variable executing_time 0
	sample
}

proc sample {} {
	variable last_executing
	variable executing_time
	variable sample_time
	set executing [debug probe read VDP.commandExecuting]
	set time [machine_info time]
	if {$last_executing} {
		set executing_time [expr {$time - $sample_time + $executing_time}]
	}
	set last_executing $executing
	set sample_time $time
}

proc display {} {
	variable executing_time
	variable display_time
	variable sample_time
	variable after_id
	sample
	set percentage [expr {round(100 * $executing_time / ($sample_time - $display_time))}]
	set display_time $sample_time
	osd configure "vdp_busy.text" -text "$percentage%"
	reset
	set after_id [after time .25 vdp_busy::display]
}

proc toggle_vdp_busy {} {
	variable bp_id
	variable after_id
	if [info exists bp_id] {
		debug probe remove_bp $bp_id
		after cancel $after_id
		osd destroy "vdp_busy"
		unset bp_id
		unset after_id
	} else {
		osd create rectangle "vdp_busy" \
			-x 5 -y 30 -w 42 -h 20 -alpha 0x80
		osd create text "vdp_busy.text" \
			-x 5 -y 3 -rgb 0xffffff
		reset
		set bp_id [debug probe set_bp VDP.commandExecuting {} vdp_busy::sample]
		set after_id [after time .25 vdp_busy::display]
	}
	return ""
}

namespace export toggle_vdp_busy

} ;# namespace vdp_busy

namespace import vdp_busy::*
