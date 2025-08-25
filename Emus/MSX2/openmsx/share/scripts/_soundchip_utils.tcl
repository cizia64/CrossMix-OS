# Several utility procs for usage in other scripts
# don't export anything, just use it from the namespace,
# because these scripts aren't useful for console users
# and should therefore not be exported to the global
# namespace.
#
# These procs are specifically for sound chips.
#
# Born to prevent duplication between scripts for common stuff.

namespace eval soundchip_utils {

proc get_num_channels {soundchip} {
	set num 1
	while {[info exists ::${soundchip}_ch${num}_mute]} {
		incr num
	}
	expr {$num - 1}
}

# It is advised to cache the result of this proc for each channel of each sound device
# before using it, because then a lot will be pre-evaluated and at run time only the
# actual variable stuff will be evaluated.
# We cannot cache it here, because we don't know the names of the sound chips in the
# machine you are going to use this on.
# @param soundchip the name of the soundchip as it appears in the output of
# "machine_info sounddevice"
# @channel the channel for which you want the expression to get the volume, the
# first channel is channel 0 and the channels are the ones as they are output
# by the record_channels command.
# @return expression to calculate the volume of the device for that channel in
# range [0-1]; returns just 'x' in case the chip is not supported.
# @todo:
#  - frequency expressions for (some of?) the drum channels are not correct
#  - implement volume for MoonSound FM (tricky stuff)
#  - actually, don't use regs to calc volume but actual wave data (needs openMSX
#    changes)
#
proc get_volume_expr {soundchip channel} {
	switch [machine_info sounddevice $soundchip] {
		"PSG" {
			set regs "\"${soundchip} regs\""
			return "set keybits \[debug read $regs 7\]; set val \[debug read $regs [expr {$channel + 8}]\]; expr {(\$val & 0x10) ? 1.0 : ((\$val & 0xF) / 15.0) * !((\$keybits >> $channel) & (\$keybits >> [expr {$channel + 3}]) & 1)}"
		}
		"MoonSound wave-part" {
			set regs "\"${soundchip} regs\""
			return "expr {((\[debug read $regs [expr {$channel + 0x68}]\]) >> 7) ? (127 - (\[debug read $regs [expr {$channel + 0x50}]\] >> 1)) / 127.0 : 0.0}";
		}
		"Konami SCC" -
		"Konami SCC+" {
			set regs "\"${soundchip} SCC\""
			return "expr {((\[debug read $regs [expr {$channel + 0xAA}]\] &0xF)) / 15.0 * ((\[debug read $regs 0xAF\] >> $channel) &1)}"
		}
		"MSX-MUSIC" {
			set regs "\"${soundchip} regs\""
			set vol_expr "(\[debug read $regs [expr {$channel + 0x30}]\] & 0x0F)"
			set keyon_expr "(\[debug read $regs [expr {$channel + 0x20}]\] & 0x10)"
			set music_mode_expr "$keyon_expr ? ((15 - $vol_expr) / 15.0) : 0.0"
			set rhythm_expr "\[debug read $regs 0x0E\]"
			if {$channel < 6} {
				# always melody channel
				return "expr {$music_mode_expr}"
			} elseif {$channel < 9} {
				# melody channel when not in rhythm mode
				return "expr {($rhythm_expr & 0x20) ? 0.0 : $music_mode_expr}"
			} elseif {$channel < 14} {
				# rhythm channel (when rhythm mode enabled)
				if {$channel < 12} {
					set vol_expr "(\[debug read $regs [expr {$channel + 0x30 - 3}]\] & 0x0F)"
				} else {
					set vol_expr "(\[debug read $regs [expr {$channel + 0x2E - 3}]\] >> 4)"
				}
				switch $channel {
					 9 {set mask 0x30} ;# BD
					10 {set mask 0x28} ;# SD
					11 {set mask 0x22} ;# T-CYM
					12 {set mask 0x21} ;# HH
					13 {set mask 0x24} ;# TOM
				}
				return "expr {($rhythm_expr & $mask) ? (15 - $vol_expr) / 15.0 : 0.0}"
			} else {
				error "Unknown channel: $channel for $soundchip!"
			}
		}
		"MSX-AUDIO" {
			set regs "\"${soundchip} regs\""
			set ofst [expr {0x43 + $channel + 5 * ($channel / 3)}]
			set keyon_expr "(\[debug read $regs [expr {$channel + 0xB0}]\] & 0x20)"
			set vol_expr {(63 - (\[debug read $regs $ofst\] & 63)) / 63.0}
			set music_mode_expr "($keyon_expr ? [subst $vol_expr] : 0.0)"
			set rhythm_expr "\[debug read $regs 0xBD\]"
			if {$channel < 6} {
				# always melody channel
				return "expr {$music_mode_expr}"
			} elseif {$channel < 9} {
				# melody channel when not in rhythm mode
				return "expr {($rhythm_expr & 0x20) ? 0.0 : $music_mode_expr}"
			} elseif {$channel < 14} {
				# rhythm channel (when rhythm mode enabled)
				switch $channel {
					 9 {set mask 0x30; set ofst 0x53} ;# BD  (slot 16)
					10 {set mask 0x28; set ofst 0x54} ;# SD  (slot 17)
					11 {set mask 0x22; set ofst 0x55} ;# CYM (slot 18)
					12 {set mask 0x21; set ofst 0x51} ;# HH  (slot 13)
					13 {set mask 0x24; set ofst 0x52} ;# TOM (slot 14)
				}
				return "expr {($rhythm_expr & $mask) ? [subst $vol_expr] : 0.0}"
			} elseif {$channel < 15} {
				# ADPCM
				# can we output 0 when no sample is playing?
				return "expr {\[debug read $regs 0x12\] / 255.0}"
			} else {
				error "Unknown channel: $channel for $soundchip!"
			}
		}
		"DCSG" {
			set regs "\"${soundchip} regs\""
			set addr [expr {$channel*3 + 2}]
			if {${channel} == 3} {
				incr addr -1
			}
			return "expr {(15 - \[debug read $regs $addr\]) / 15.0}"
		}
		default {
			return "x"
		}
	}
}

# It is advised to cache the result of this proc for each channel of each sound device
# before using it, because then a lot will be pre-evaluated and at run time only the
# actual variable stuff will be evaluated.
# We cannot cache it here, because we don't know the names of the sound chips in the
# machine you are going to use this on.
# @param soundchip the name of the soundchip as it appears in the output of
# "machine_info sounddevice"
# @channel the channel for which you want the expression to get the frequency, the
# first channel is channel 0 and the channels are the ones as they are output
# by the record_channels command.
# @return expression to calculate the frequency of the device for that channel in
# Hz; returns just 'x' in case the chip is not supported.
# @todo:
#  - implement frequency for MoonSound
#
proc get_frequency_expr {soundchip channel} {
	switch [machine_info sounddevice $soundchip] {
		"PSG" {
			set regs "\"${soundchip} regs\""
			set basefreq [expr {3579545.454545 / 32.0}]
			return "set val \[expr {\[debug read $regs \[expr {0 + ($channel * 2)}\]\] + 256 * ((\[debug read $regs \[expr {1 + ($channel * 2)}\]\]) & 15)}\]; expr {$basefreq/(\$val < 1 ? 1 : \$val)}"
		}
		"Konami SCC" -
		"Konami SCC+" {
			set regs "\"${soundchip} SCC\""
			set basefreq [expr {3579545.454545 / 32.0}]
			return "set val \[expr {\[debug read $regs \[expr {0xA0 + 0 + ($channel * 2)}\]\] + 256 * ((\[debug read $regs \[expr {0xA0 + 1 + ($channel * 2)}\]\]) & 15)}\]; expr {$basefreq/(\$val < 1 ? 1 : \$val)}"
		}
		"MSX-MUSIC" {
			set regs "\"${soundchip} regs\""
			set basefreq [expr {3579545.454545 / 72.0}]
			set factor [expr {$basefreq / (1 << 18)}]
			if {$channel >= 9} {
				#drums
				incr channel -3
			}
			return "expr {(\[debug read $regs [expr {$channel + 0x10}]\] + 256 * ((\[debug read $regs [expr {$channel + 0x20}]\]) & 1)) * $factor * (1 << (((\[debug read $regs [expr {$channel + 0x20}]\]) & 15) >> 1))}"
		}
		"MSX-AUDIO" {
			set regs "\"${soundchip} regs\""
			set basefreq [expr {3579545.454545 / 72.0}]
			if {$channel == 14} { ;# ADPCM
				set factor [expr {$basefreq / (1 << 16)}]
				return "expr {(\[debug read $regs 0x10\] + 256 * \[debug read $regs 0x11\]) * $factor / 10}";# /10 is just to make it fall a bit into a decent range...
			} else {
				set factor [expr {$basefreq / (1 << 19)}]
				if {$channel >= 9} {
					#drums
					incr channel -3
				}
				return "expr {(\[debug read $regs [expr {$channel + 0xA0}]\] + 256 * ((\[debug read $regs [expr {$channel + 0xB0}]\]) & 3)) * $factor * (1 << (((\[debug read $regs [expr {$channel + 0xB0}]\]) & 31) >> 2))}"
			}
		}
		"DCSG" {
			set regs "\"${soundchip} regs\""
			set basefreq [expr {(3579545.454545 / 8.0) / 2.0}]
			set addr [expr {$channel*3}]
			set next_addr [expr {$addr + 1}]
			if {${channel} == 3} {
				# noise channel not supported
				return "x"
			} else {
				return "set period \[expr {\[debug read $regs $addr\] + (\[debug read $regs $next_addr\] << 4)}\]; if {\$period == 0} {set period 1024}; expr {$basefreq / (2*\$period)}"
			}
		}
		default {
			return "x"
		}
	}
}

namespace export get_num_channels
namespace export get_volume_expr
namespace export get_frequency_expr

} ;# namespace soundchip_utils

# Don't import in global namespace, these are only useful in other scripts.
