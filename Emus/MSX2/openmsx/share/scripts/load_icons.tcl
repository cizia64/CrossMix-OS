namespace eval load_icons {

set_help_text load_icons \
{Load a different set of OSD icons.
 usage:  load_icons [<name> [<position>]]
   <name> is the name of a directory (share/skins/<name>) that
          contains the icon images. If this parameter is not given,
          a list of available skins will be printed.
   <position> can be one of the following 'bottom', 'top', 'left'
              or 'right'. The default depends on the selected skin.
 example: load_icons set1 top
}

set_tabcompletion_proc load_icons [namespace code tab_load_icons]
proc tab_load_icons {args} {
	set num [llength $args]
	if {$num == 2} {
		set r1 [glob -nocomplain -tails -type d -directory $::env(OPENMSX_USER_DATA)/skins *]
		set r2 [glob -nocomplain -tails -type d -directory $::env(OPENMSX_SYSTEM_DATA)/skins *]
		concat $r1 $r2
	} elseif {$num == 3} {
		list "top" "bottom" "left" "right"
	}
}

variable icon_list
variable last_change
variable current_osd_leds_set
variable current_osd_leds_pos
variable current_fade_delay_active
variable current_fade_delay_non_active
variable fade_id

# temporary hack: for now map the new 'fastforward' setting onto the old 'throttle' setting
proc trace_icon_status {name1 name2 op} {
	variable last_change
	global $name1
	set icon [string trimleft $name1 ":"]
	if {$icon eq "fastforward"} {set icon "throttle"}
	set now [openmsx_info realtime]
	set last_change($icon) $now
	redraw_osd_icons $icon $now
}

proc redraw_osd_icons {icon now} {
	variable last_change
	variable current_fade_delay_active
	variable current_fade_delay_non_active
	variable fade_id
	global $icon

	# handle 'unset' variables  (when current msx machine got deleted)
	if {[catch {
		if {$icon eq "throttle"} {
			set value [expr {$::throttle && !$::fastforward}]
		} else {
			set value [set $icon]
		}
	}]} {
		set value false
	}

	if {$value} {
		set widget  osd_icons.${icon}_on
		set widget2 osd_icons.${icon}_off
		set fade_delay $current_fade_delay_active($icon)
	} else {
		set widget  osd_icons.${icon}_off
		set widget2 osd_icons.${icon}_on
		set fade_delay $current_fade_delay_non_active($icon)
	}
	osd configure $widget2 -fadeCurrent 0 -fadeTarget 0

	catch {after cancel $fade_id($icon)}
	if {$fade_delay == 0} {
		# remains permanently visible (no fading)
		osd configure $widget -fadeCurrent 1 -fadeTarget 1
	} else {
		set target [expr {$last_change($icon) + $fade_delay}] ;# at this time we start fading out
		set remaining [expr {$target - $now}] ;# time remaining from now to target
		set cmd "osd configure $widget -fadeTarget 0"
		if {$remaining > 0} {
			# before target time, no fading yet (still fully visible)
			osd configure $widget -fadeCurrent 1 -fadeTarget 1
			# schedule fade-out in the future
			set fade_id($icon) [after realtime $remaining $cmd]
		} else {
			# already after target, fade-out now
			eval $cmd
		}
	}
}

proc load_icons {{set_name "-show"} {position_param "default"}} {
	variable icon_list
	variable current_osd_leds_set
	variable current_osd_leds_pos
	variable current_fade_delay_active
	variable current_fade_delay_non_active

	set possible_positions [list "top" "bottom" "left" "right" "default"]

	if {$set_name eq "-show"} {
		# Show list of available skins
		set user_skins [list]
		catch {
			set user_skins   \
			    [glob -tails -types d -directory $::env(OPENMSX_USER_DATA)/skins   *]
		}

		set system_skins [list]
		catch {
			set system_skins \
			    [glob -tails -types d -directory $::env(OPENMSX_SYSTEM_DATA)/skins *]
		}
		return "Current icon set is $::osd_leds_set at position $::osd_leds_pos.\nAvailable sets: [lsort -unique [concat $user_skins $system_skins]]\nPossible positions: $possible_positions"
	}

	# Check skin directory
	#  All files belonging to this skin must come from this directory.
	#  So we don't allow mixing individual files for one skin from the
	#  system and from the user directory. Though fallback images are
	#  again searched in both system and user dirs.
	set skin_set_dir [data_file "skins/$set_name"]
	if {![file isdirectory $skin_set_dir]} {
		error "No such icon skin: $set_name"
	}

	# Check position
	if {$position_param ni $possible_positions} {
		error "Invalid position: $position_param"
	}

	# Defaut icon positions
	set xbase 0
	set ybase 0
	set xwidth 50
	set yheight 30
	set xspacing 60
	set yspacing 35
	set horizontal 1
	set fade_delay 5
	set fade_duration 5
	set scale 2
	set position $position_param

	# but allow to override these values by the skin script
	set icons $icon_list  ;# the 'none' skin needs this
	set script $skin_set_dir/skin.tcl
	if {[file isfile $script]} {source $script}

	set invscale [expr {1.0 / $scale}]
	set xbase    [expr {$xbase    * $invscale}]
	set ybase    [expr {$ybase    * $invscale}]
	set xwidth   [expr {$xwidth   * $invscale}]
	set yheight  [expr {$yheight  * $invscale}]
	set xspacing [expr {$xspacing * $invscale}]
	set yspacing [expr {$yspacing * $invscale}]

	# change according to <position> parameter
	if {$position eq "default"} {
		# script didn't set a default, so we choose a "default default"
		set position "bottom"
	}
	if {$position eq "left"} {
		set horizontal 0
	} elseif {$position eq "right"} {
		set horizontal 0
	        set xbase [expr {320 - $xwidth}]
	} elseif {$position eq "bottom"} {
	        set ybase [expr {240 - $yheight}]
	}
	set vertical [expr {!$horizontal}]

	proc __try_dirs {skin_set_dir file fallback} {
		# don't touch already resolved pathnames
		if {[file normalize $file] eq $file} {return $file}
		# first look in specified skin-set directory
		set f1 [file normalize $skin_set_dir/$file]
		if {[file isfile $f1]} {return $f1}
		# look for the falback image in the skin directory
		set f2 [file normalize $skin_set_dir/$fallback]
		if {[file isfile $f2]} {return $f2}
		# if it's not there look in the root skin directory
		# (system or user directory)
		set f3 [file normalize [data_file "skins/$file"]]
		if {[file isfile $f3]} {return $f3}
		# still not found, look for the fallback image in system and
		# user root skin dir
		set f4 [file normalize [data_file "skins/$fallback"]]
		if {[file isfile $f4]} {return $f4}
		return ""
	}
	# Calculate default parameter values ...
	for {set i 0} {$i < [llength $icons]} {incr i} {
		set icon [lindex $icons $i]

		set xcoord($icon) [expr {$i * $xspacing * $horizontal}]
		set ycoord($icon) [expr {$i * $yspacing * $vertical}]

		set fade_delay_active($icon)     $fade_delay
		set fade_delay_non_active($icon) $fade_delay

		set fade_duration_active($icon)     $fade_duration
		set fade_duration_non_active($icon) $fade_duration

		switch -glob $icon {
			led_* {
				set base [string tolower [string range $icon 4 end]]
				set image_on     "${base}-on.png"
				set image_off    "${base}-off.png"
				set fallback_on  "led-on.png"
				set fallback_off "led-off.png"
			}
			throttle {
				set image_on     ""
				set image_off    "${icon}.png"
				set fallback_on  ""
				set fallback_off ""
				set current_fade_delay_non_active($icon) 0
			}
			default {
				set image_on     "${icon}.png"
				set image_off    ""
				set fallback_on  ""
				set fallback_off ""
				set fade_delay_active($icon) 0
			}
		}
		set active_image($icon)     [__try_dirs $skin_set_dir $image_on  $fallback_on ]
		set non_active_image($icon) [__try_dirs $skin_set_dir $image_off $fallback_off]
	}

	# ... but allow to override these calculated values (again) by the skin script
	if {[file isfile $script]} {source $script}

	# Note: The actual width and height are irrelevant since this is only
	#       an anchor to relatively position the icons to, but by checking
	#       for a zero or non-zero value the orientation can be queried.
	osd configure osd_icons -x $xbase -y $ybase -w $horizontal -h $vertical

	foreach icon $icon_list {
		osd configure osd_icons.${icon}_on \
		       -x $xcoord($icon) \
		       -y $ycoord($icon) \
		       -fadePeriod $fade_duration_active($icon) \
		       -image [__try_dirs $skin_set_dir $active_image($icon) ""] \
		       -scale $invscale
		osd configure osd_icons.${icon}_off \
		       -x $xcoord($icon) \
		       -y $ycoord($icon) \
		       -fadePeriod $fade_duration_non_active($icon) \
		       -image [__try_dirs $skin_set_dir $non_active_image($icon) ""] \
		       -scale $invscale
	}

	# Also try to load "frame.png"
	osd destroy osd_frame
	set framefile "$skin_set_dir/frame.png"
	if {[file isfile $framefile]} {
		osd create rectangle osd_frame -z 0 -x 0 -y 0 -w 320 -h 240 \
		                               -scaled true -image $framefile
	}

	# If successful, store in settings (order of assignments is important!)
	set current_osd_leds_set $set_name
	set ::osd_leds_set $set_name
	set current_osd_leds_pos $position_param
	set ::osd_leds_pos $position_param
	foreach icon $icon_list {
		set current_fade_delay_active($icon)     $fade_delay_active($icon)
		set current_fade_delay_non_active($icon) $fade_delay_non_active($icon)
	}

	# Force redrawing of all icons
	set now [openmsx_info realtime]
	foreach icon $icon_list {
		redraw_osd_icons $icon $now
	}
	return ""
}

proc trace_osd_icon_vars {name1 name2 op} {
	variable current_osd_leds_set
	variable current_osd_leds_pos

	# avoid executing load_icons multiple times
	# (because of the assignments to the settings in that proc)
	if {($::osd_leds_set eq $current_osd_leds_set) &&
	    ($::osd_leds_pos eq $current_osd_leds_pos)} {
		return
	}
	load_icons $::osd_leds_set $::osd_leds_pos
}

proc machine_switch_osd_icons {} {
	variable icon_list

	set now [openmsx_info realtime]
	foreach icon $icon_list {
		trace remove variable ::$icon "write unset" [namespace code trace_icon_status]
		trace add    variable ::$icon "write unset" [namespace code trace_icon_status]
		redraw_osd_icons $icon $now
	}
	trace remove variable ::fastforward "write unset" [namespace code trace_icon_status]
	trace add    variable ::fastforward "write unset" [namespace code trace_icon_status]
	after machine_switch [namespace code machine_switch_osd_icons]
}

# Available icons. Icons are also drawn in this order (by default)
set icon_list [list "led_power" "led_caps" "led_kana" "led_pause" "led_turbo" "led_FDD" \
                    "pause" "throttle" "mute" "breaked"]

# create OSD widgets
osd create rectangle osd_icons -scaled true -alpha 0 -z 1
set now [openmsx_info realtime]
foreach icon $icon_list {
	variable last_change
	osd create rectangle osd_icons.${icon}_on  -fadeCurrent 0 -fadeTarget 0 -fadePeriod 5.0
	osd create rectangle osd_icons.${icon}_off -fadeCurrent 0 -fadeTarget 0 -fadePeriod 5.0
	trace add variable ::$icon "write unset" load_icons::trace_icon_status
	set last_change($icon) $now
}
trace add variable ::fastforward "write unset" load_icons::trace_icon_status

namespace export load_icons

} ;# namespace load_icons

namespace import load_icons::*

# Restore settings from previous session
# default is set1, but if only scale_factor 1 is supported, use handheld
if {[lindex [openmsx_info setting scale_factor] 2 1] == 1} {
	user_setting create string osd_leds_set "Name of the OSD icon set" "handheld"
} else {
	user_setting create string osd_leds_set "Name of the OSD icon set" "set1"
}
user_setting create string osd_leds_pos "Position of the OSD icons" "default"
set load_icons::current_osd_leds_set $osd_leds_set
set load_icons::current_osd_leds_pos $osd_leds_pos
trace add variable osd_leds_set write load_icons::trace_osd_icon_vars
trace add variable osd_leds_pos write load_icons::trace_osd_icon_vars
after machine_switch load_icons::machine_switch_osd_icons

load_icons $osd_leds_set $osd_leds_pos
