# VU-meters, just for fun.
#
# Search in the script for 'customized' to see what you could customize ;-)
#
# The volume calculations are the volume setting of the channel, unless nothing
# is played, then 0 is output. This is done by looking at 'key on' bits, as far
# as they exist.
#
# TODO:
# - optimize more?
# - handle insertion/removal of sound devices (needs openMSX changes)
#
# Thanks to BiFi for helping out with the expressions for the devices.
# Thanks to Wouter for the Tcl support.

set_help_text toggle_vu_meters \
{Puts a rough volume unit display for each channel and for all sound chips on
the On-Screen-Display. Use the command again to remove it. Note: it cannot
handle run-time insertion/removal of sound devices. It can handle changing
of machines, though. Not all chips are supported yet.
Note that displaying these VU-meters may cause quite some CPU load!}

namespace eval vu_meters {

variable vu_meters_active false
variable volume_cache
variable volume_expr
variable bar_length
variable machine_switch_trigger_id 0
variable frame_trigger_id 0

proc vu_meters_init {} {
	variable volume_cache
	variable volume_expr
	variable bar_length
	variable machine_switch_trigger_id

	# create root object for vu_meters
	osd create rectangle vu_meters \
		-scaled true \
		-alpha 0 \
		-z 1

	foreach soundchip [machine_info sounddevice] {
		# skip devices which don't have volume expressions (not implemented yet)
		if {[soundchip_utils::get_volume_expr $soundchip 0] eq "x"} continue

		# determine number of channels
		set channel_count [soundchip_utils::get_num_channels $soundchip]

		for {set i 0} {$i < $channel_count} {incr i} {
			# create the volume cache and the expressions
			dict set volume_cache $soundchip $i -1
			dict set volume_expr  $soundchip $i [soundchip_utils::get_volume_expr $soundchip $i]
		}
	}

	set nof_soundchips [dict size $volume_expr]
	set bar_width 2; # this value could be customized
	set vu_meter_title_height 8; # this value could be customized
	set bar_length [expr {(320 - $nof_soundchips) / $nof_soundchips}]
	if {$bar_length > (320 / 4)} {set bar_length [expr {320 / 4}]}

	# create widgets for each sound chip:
	set vu_meter_offset 0

	dict for {soundchip channel_dict} $volume_expr {
		set nof_channels [dict size $channel_dict]
		# create surrounding widget for this chip
		osd create rectangle vu_meters.$soundchip \
			-rgba 0x00000080 \
			-x ${vu_meter_offset} \
			-y 0 \
			-w $bar_length \
			-h [expr {$vu_meter_title_height + 1 + $nof_channels * ($bar_width + 1)}] \
			-clip true
		osd create text vu_meters.${soundchip}.title \
			-x 1 \
			-y 1 \
			-rgba 0xffffffff \
			-text $soundchip \
			-size [expr {$vu_meter_title_height - 1}]

		# create vu meters for this sound chip
		dict for {channel volExpr} $channel_dict {
			osd create rectangle vu_meters.${soundchip}.ch${channel} \
				-rgba 0xff0000ff \
				-x 0 \
				-y [expr {$vu_meter_title_height + 1 + (($bar_width + 1) * $channel)}] \
				-w 0 \
				-h $bar_width \
		}

		incr vu_meter_offset [expr {$bar_length + 1}]
	}

	set machine_switch_trigger_id [after machine_switch [namespace code vu_meters_reset]]
}

proc update_meters {} {
	variable vu_meters_active
	variable volume_cache
	variable volume_expr
	variable frame_trigger_id

	# update meters with the volumes
	if {!$vu_meters_active} return

	if {[catch {
		dict for {soundchip channel_dict} $volume_expr {
			dict for {channel volExpr} $channel_dict {
				set new_volume [eval $volExpr]
				if {[dict get $volume_cache $soundchip $channel] != $new_volume} {
					dict set volume_cache $soundchip $channel $new_volume
					update_meter "vu_meters.${soundchip}.ch${channel}" $new_volume
				}
			}
		}
	}]} {
		# a chip disappeared probably, let's reinit to see which there are now
		vu_meters_reinit
	}
	# here you can customize the update frequency (to reduce CPU load)
	#set frame_trigger_id [after time 0.05 [namespace code update_meters]]
	set frame_trigger_id [after frame [namespace code update_meters]]
}

proc update_meter {meter volume} {
	variable bar_length

	set byte_val [expr {round(255 * $volume)}]
	set col1 0x008000C0
	set col2 [expr {($byte_val << 24) + $col1}]
	osd configure $meter \
		-w [expr {$bar_length * $volume}] \
		-rgba "$col1 $col2 $col1 $col2"
}


proc vu_meters_reset {} {
	variable vu_meters_active
	if {!$vu_meters_active} {
		error "Please fix a bug in this script!"
	}
	toggle_vu_meters
	toggle_vu_meters
}

proc toggle_vu_meters {} {
	variable vu_meters_active
	variable machine_switch_trigger_id
	variable frame_trigger_id
	variable bar_length
	variable volume_cache
	variable volume_expr

	if {$vu_meters_active} {
		after cancel $machine_switch_trigger_id
		after cancel $frame_trigger_id
		set vu_meters_active false
		osd destroy vu_meters
		unset bar_length volume_cache volume_expr
	} else {
		set vu_meters_active true
		vu_meters_init
		update_meters
	}
	return ""
}

proc vu_meters_reinit {} {
	toggle_vu_meters
	toggle_vu_meters
}

namespace export toggle_vu_meters

} ;# namespace vu_meters

namespace import vu_meters::*
