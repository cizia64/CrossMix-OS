# Shows an info panel similar to the blueMSX DIGIblue theme
#
# TODO:
# - make layout more flexible?
# - make sure it doesn't interfere with LEDs?

namespace eval info_panel {

variable info_panel_active false
variable textheight 15
variable panel_margin 2
variable sub_panel_height [expr {$textheight * 2 + $panel_margin}]
variable panel_info

proc info_panel_init {} {
	variable info_panel_active
	variable textheight
	variable panel_margin
	variable sub_panel_height
	variable panel_info

	set panel_info [dict create \
		software [dict create \
			title "Running software" width 400 row 0 \
			method guess_title] \
		mapper [dict create \
			title "Mapper type" width 170 row 0 \
			method {set val ""; catch {set val [dict get [openmsx_info romtype [dict get [machine_info device [guess_rom_device]] "mappertype"]] description]}; set val}] \
		fps [dict create \
			title "FPS" width 38 row 1 \
			method {format "%2.1f" [openmsx_info fps]}] \
		screen [dict create \
			title "Screen" width 50 row 1 \
			method {get_screen_mode}] \
		vram [dict create \
			title "VRAM" width 42 row 1 \
			method {format "%dkB" [expr {[debug size "physical VRAM"] / 1024}]}] \
		ram [dict create \
			title "RAM" width 51 row 1 \
			method {set ramsize 0; foreach device [debug list] {set desc [debug desc $device]; if {$desc eq "memory mapper" || $desc eq "ram"} {incr ramsize [debug size $device]}}; format "%dkB" [expr {$ramsize / 1024}]}] \
		mtime [dict create \
			title "Time" width 60 row 1 \
			method {utils::get_machine_time}] \
		speed [dict create \
			title "Speed" width 48 row 1 \
			method {format "%d%%" [expr {round([get_actual_speed] * 100)}]}] \
		machine [dict create \
			title "Machine name and type" width 250 row 1 \
			method {
				set name [utils::get_machine_display_name]
				if {[catch {
					set type [dict get [openmsx_info machines [machine_info config_name]] type]
					set result [format "%s (%s)" $name $type]
				}]} {
					set result $name
				}
				set result
			}] \
		]

	# calc width of software item
	set software_width 0
	dict for {name info} $panel_info {
		if {[dict get $info row] == 1} {
			incr software_width [dict get $info width]
			incr software_width $panel_margin
		} elseif {$name ne "software"} {
			incr software_width -[dict get $info width]
			incr software_width -$panel_margin
		}
	}
	incr software_width -$panel_margin
	dict set panel_info software width $software_width

	# set base element
	osd create rectangle info_panel \
		-x $panel_margin \
		-y [expr {-($sub_panel_height * 2 + (2 * $panel_margin))}] \
		-rely 1.0 \
		-alpha 0

	# create subpanels
	set curpos [dict create 0 0 1 0]
	dict for {name info} $panel_info {
		set row [dict get $info row]
		create_sub_panel $name \
		                 [dict get $info title] \
		                 [dict get $info width] \
		                 [dict get $info row] \
		                 [dict get $curpos $row]
		dict incr curpos $row [expr {[dict get $info width] + $panel_margin}]
	}
}

proc create_sub_panel {name title width row pos} {
	variable textheight
	variable panel_margin
	variable sub_panel_height

	osd create rectangle info_panel.$name \
		-x $pos \
		-y [expr {($sub_panel_height + $panel_margin) * $row}] \
		-h $sub_panel_height \
		-w $width \
		-rgba 0x00005080 \
		-clip true
	osd create text info_panel.$name.title \
		-x 2 \
		-y 0 \
		-rgba 0xddddffff \
		-text $title \
		-size [expr {int($textheight * 0.8)}]
	osd create text info_panel.$name.value \
		-x 2 \
		-y $textheight \
		-rgba 0xffffffff \
		-text $name \
		-size [expr {int($textheight * 0.9)}]
}

proc update_info_panel {} {
	variable info_panel_active
	variable panel_info

	if {!$info_panel_active} return

	dict for {name info} $panel_info {
		osd configure info_panel.$name.value -text [eval [dict get $info method]]
	}
	after realtime 1 [namespace code update_info_panel]
}

proc toggle_info_panel {} {
	variable info_panel_active

	if {$info_panel_active} {
		set info_panel_active false
		osd destroy info_panel
	} else {
		set info_panel_active true
		info_panel_init
		update_info_panel
	}
	return ""
}

## Stuff to calculate the actual speed (could be made public later)

# We keep two past data points (a data point consist out of a measured
# emutime and realtime). These two data points are at least 1 second
# apart in realtime.
variable last_emutime1  -1.0
variable last_realtime1 -1.0
variable last_emutime2   0.0
variable last_realtime2  0.0

proc get_actual_speed {} {
	variable last_emutime1
	variable last_emutime2
	variable last_realtime1
	variable last_realtime2

	set curr_emutime  [machine_info time]
	set curr_realtime [openmsx_info realtime]

	set diff_realtime [expr {$curr_realtime - $last_realtime2}]
	if {$diff_realtime > 1.0} {
		# Younger data point is old enough. Drop older data point and
		# make current measurement a new data point.
		set last_emutime   $last_emutime2
		set last_emutime1  $last_emutime2
		set last_emutime2  $curr_emutime
		set last_realtime1 $last_realtime2
		set last_realtime2 $curr_realtime
	} else {
		# Take older data point, don't change recorded data.
		set last_emutime  $last_emutime1
		set diff_realtime [expr {$curr_realtime - $last_realtime1}]
	}
	return [expr {($curr_emutime - $last_emutime) / $diff_realtime}]
}

namespace export toggle_info_panel

} ;# namespace info_panel

namespace import info_panel::*
