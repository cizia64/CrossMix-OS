namespace eval record_channels {

set_help_text record_channels \
{Convenience function to control recording of individual channels of
sounddevice(s).

There are three subcommands (start, stop and list) to respectively start
recording additional channels, to stop recording all or some channels and
to list which channels are currently being recorded.
  record_channels [start] [<device> [<channels>]]
  record_channels  stop   [<device> [<channels>]]
  record_channels  list
When starting recording, you can optionally specify a prefix for the
destination file names with the -prefix option.

Some examples will make it much clearer:
  - To start recording:
      record_channels start PSG      record all PSG channels
      record_channels PSG            the 'start' keyword can be left out
      record_channels SCC 1,3-5      only record channels 1 and 3 to 5
      record_channels SCC PSG 1      record all SCC channels + PSG channel 1
      record_channels all            record all channels of all devices
      record_channels all -prefix t  record all channels of all devices using
                                     prefix 't'
  - To stop recording
      record_channels stop           stop all recording
      record_channels stop PSG       stop recording all PSG channels
      record_channels stop SCC 3,5   stop recording SCC channels 3 and 5
  - To show the current status
      record_channels list           shows which channels are being recorded
}

set mute_help_text \
{Convenience function to control (un)muting of individual channels of
soundevice(s).

Examples:
  mute_channels PSG               mute all PSG channels
  mute_channels SCC 2,4           mute SCC channels 2 and 4
  unmute_channels PSG 1 SCC 3-5   unmute PSG channel 1, SCC channels 3 to 5
  mute_channels                   show which channels are currently muted
  unmute_channels                 unmute all channels on all devices
  solo PSG 2                      mute everything except PSG channel 2
}
set_help_text mute_channels   $mute_help_text
set_help_text unmute_channels $mute_help_text
set_help_text solo            $mute_help_text

set_tabcompletion_proc record_channels [namespace code tab_sounddevice_channels]
set_tabcompletion_proc mute_channels   [namespace code tab_sounddevice_channels]
set_tabcompletion_proc unmute_channels [namespace code tab_sounddevice_channels]
set_tabcompletion_proc solo            [namespace code tab_sounddevice_channels]
proc tab_sounddevice_channels {args} {
	set result [machine_info sounddevice]
	if {([lindex $args 0] eq "record_channels") && ([llength $args] == 2)} {
		set result [concat $result "start stop list all"]
	}
	return $result
}

proc parse_channel_numbers {str} {
	set result [list]
	foreach a [split $str ", "] {
		set b [split $a "-"]
		foreach c $b {
			if {![string is integer $c]} {
				error "Not an integer: $c"
			}
		}
		switch [llength $b] {
			0 {}
			1 {lappend result [lindex $b 0]}
			2 {for {set i [lindex $b 0]} {$i <= [lindex $b 1]} {incr i} {
				lappend result $i
			}}
			default {error "Invalid range: $a"}
		}
	}
	return [lsort -unique $result]
}

proc get_all_channels {device} {
	set i 1
	set channels [list]
	while {[info exists ::${device}_ch${i}_record]} {
		lappend channels $i
		incr i
	}
	return $channels
}

proc get_all_devices_all_channels {} {
	set result [list]
	foreach device [machine_info sounddevice] {
		lappend result $device [get_all_channels $device]
	}
	return $result
}

proc get_recording_channels {} {
	set result [list]
	set sounddevices [machine_info sounddevice]
	foreach device $sounddevices {
		set active [list]
		foreach ch [get_all_channels $device] {
			set var ::${device}_ch${ch}_record
			if {[set $var] ne ""} {
				lappend active $ch
			}
		}
		if {[llength $active]} {
			lappend result "$device: $active"
		}
	}
	return $result
}

proc get_muted_channels {} {
	set result [list]
	set sounddevices [machine_info sounddevice]
	foreach device $sounddevices {
		set active [list]
		foreach ch [get_all_channels $device] {
			set var ::${device}_ch${ch}_mute
			if {[set $var]} {
				lappend active $ch
			}
		}
		if {[llength $active]} {
			lappend result "$device: $active"
		}
	}
	return $result
}

proc parse_device_channels {tokens} {
	set sounddevices [machine_info sounddevice]
	set device_channels [list]
	if {[lindex $tokens 0] == "all"} {
		foreach device $sounddevices {
			lappend device_channels $device [get_all_channels $device]
		}
		return $device_channels
	}
	while {[llength $tokens]} {
		set device [lindex $tokens 0]
		set tokens [lrange $tokens 1 end]
		if {$device ni $sounddevices} {
			error "Unknown sounddevice: $device"
		}
		set range [lindex $tokens 0]
		if {($range ne "") && ($range ni $sounddevices)} {
			set channels [parse_channel_numbers $range]
			set tokens [lrange $tokens 1 end]
			foreach ch $channels {
				if {![info exists ::${device}_ch${ch}_record]} {
					error "No channel $ch on sounddevice $device"
				}
			}
		} else {
			set channels [get_all_channels $device]
		}
		lappend device_channels $device $channels
	}
	return $device_channels
}

proc record_channels {args} {
	set start true
	set device_channels [list]

	# parse subcommand (default is start)
	set first [lindex $args 0]
	switch $first {
		list {
			return [join [get_recording_channels] "\n"]
		}
		start -
		stop {
			set start [string equal $first "start"]
			set args [lrange $args 1 end]
		}
	}

	if {$start} {
		set prefix [utils::filename_clean [guess_title]]
		# see if there's a -prefix option to override the default
		set prefix_index [lsearch -exact $args "-prefix"]
		if {$prefix_index >= 0 && $prefix_index < ([llength $args] - 1)} {
			set prefix [lindex $args [expr {$prefix_index + 1}]]
			set args [lreplace $args $prefix_index [expr {$prefix_index + 1}]]
		}
	}

	# parse devices/channels
	set device_channels [parse_device_channels $args]

	# stop without any further arguments -> stop all
	if {!$start && ![llength $device_channels]} {
		foreach device [machine_info sounddevice] {
			set channels [get_all_channels $device]
			lappend device_channels $device $channels
		}
	}

	set retval ""
	# actually start/stop recording
	foreach {device channels} $device_channels {
		foreach ch $channels {
			set var ::${device}_ch${ch}_record
			if {$start} {
				set directory [file normalize $::env(OPENMSX_USER_DATA)/../soundlogs]
				# create dir always
				file mkdir $directory
				set software_section $prefix
				if {$software_section ne ""} {
					set software_section "${software_section}-"
				}
				set $var [utils::get_next_numbered_filename $directory "${software_section}${device}-ch${ch}_" ".wav"]
				append retval "Recording $device channel $ch to [set $var]...\n"
			} else {
				if {[set $var] ne ""} {
					append retval "Stopped recording $device channel $ch to [set $var]...\n"
				}
				set $var ""
			}
		}
	}
	return $retval
}

proc do_mute_channels {device_channels state} {
	foreach {device channels} $device_channels {
		foreach ch $channels {
			set ::${device}_ch${ch}_mute $state
		}
	}
}

proc mute_channels {args} {
	# parse devices/channels
	set device_channels [parse_device_channels $args]

	# no argumnets specified, list muted channels
	if {![llength $device_channels]} {
		return [join [get_muted_channels] "\n"]
	}

	# actually mute channels
	do_mute_channels $device_channels true
}

proc unmute_channels {args} {
	# parse devices/channels
	set device_channels [parse_device_channels $args]

	# no arguments specified, unmute all channels
	if {![llength $device_channels]} {
		set device_channels [get_all_devices_all_channels]
	}

	#actually unmute channels
	do_mute_channels $device_channels false
}

proc solo {args} {
	# parse devices/channels
	set device_channels [parse_device_channels $args]

	# mute everything, unmute specified channels
	do_mute_channels [get_all_devices_all_channels] true
	do_mute_channels $device_channels false
}

namespace export record_channels
namespace export mute_channels
namespace export unmute_channels
namespace export solo

} ;# namspace record_channels

namespace import record_channels::*
