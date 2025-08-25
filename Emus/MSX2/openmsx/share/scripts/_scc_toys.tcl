# thanks to bifimsx for his help and his technical documentation @
# http://bifi.msxnet.org/msxnet/tech/scc.html
#
# TODO:
# - optimize! (A LOT!)
# - support SCC-I

set_help_text toggle_scc_viewer\
{Toggles display of the SCC viewer in which you can follow the wave forms and
volume per SCC channel in real time. Note: it doesn't explicitly support SCC-I
yet and it can take up quite some CPU load...}

namespace eval scc_toys {

#scc viewer
variable scc_viewer_active false
variable scc_devices [list]
variable num_samples 32
variable num_channels 5
variable vertical_downscale_factor 4
variable channel_height [expr {256 / $vertical_downscale_factor}]
variable machine_switch_trigger_id 0
variable frame_trigger_id 0
variable volume_address [expr {$num_samples * $num_channels + 2 * $num_channels}]

#scc editor / PSG2SCC
variable active false
variable cur_wp1
variable cur_wp2
variable latch -1
variable regs [list 0xa0 0xa1 0xa2 0xa3 0xa4 0xa5 -1 0xaf 0xaa 0xab 0xac -1 -1 -1 -1 -1]
variable select_device
variable select_device_chan 0

proc update_device_list {} {
	variable scc_devices
	variable select_device

	set scc_devices [list]
	foreach soundchip [machine_info sounddevice] {
		switch [machine_info sounddevice $soundchip] {
			"Konami SCC" -
			"Konami SCC+" {
				lappend scc_devices $soundchip
			}
		}
	}

	if {[llength $scc_devices] == 0} {
		#if no SCC is present try to plug in SCC
		if {![catch {ext scc} errorText]} {
			update_device_list
		} else {
			error "No SCC devices present and failed to insert one: $errorText"
		}
	}

	# for now, always select the first device
	set select_device [lindex $scc_devices 0]
}

proc scc_viewer_init {} {
	variable machine_switch_trigger_id
	variable scc_viewer_active
	variable scc_devices
	variable num_channels
	variable num_samples
	variable vertical_downscale_factor
	variable channel_height

	update_device_list

	#set base element
	osd create rectangle scc_viewer \
		-x 2 \
		-y 2 \
		-alpha 0 \
		-z 100

	set textheight 15
	set border_width 2
	set inter_channel_spacing 8
	set device_width [expr {$num_channels * ($num_samples + $inter_channel_spacing) \
	                       - $inter_channel_spacing + 2 * $border_width}]

	#create channels
	set number 0
	set offset 0
	foreach device $scc_devices {
		osd create rectangle scc_viewer.$device \
			-x [expr {$offset + $number * $device_width}] \
			-h [expr {$channel_height + 2 * $border_width + $textheight}] \
			-w $device_width \
			-rgba 0xffffff20 \
			-clip true
		osd create text scc_viewer.$device.title \
			-rgba 0xffffffff \
			-text $device \
			-size $textheight
		for {set chan 0} {$chan < $num_channels} {incr chan} {
			osd create rectangle scc_viewer.$device.$chan \
				-x [expr {($chan * ($num_samples + $inter_channel_spacing)) + $border_width}] \
				-y [expr {$border_width + $textheight}] \
				-h $channel_height \
				-w $num_samples \
				-rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80" \
				-borderrgba 0xffffff80 -bordersize 1 \
				-clip true
			osd create rectangle scc_viewer.$device.$chan.volume \
				-relw 1 \
				-z 1 \
				-rgba 0x0077ff80 \
				-borderrgba 0x0077ffc0 -bordersize 1
			osd create rectangle scc_viewer.$device.$chan.mid \
				-y [expr {$channel_height / 2}] \
				-h 1 \
				-relw 1 \
				-z 3 \
				-rgba 0xdd0000ff
			osd create rectangle scc_viewer.$device.$chan.mid.2 \
				-y -1 \
				-h 3 \
				-relw 1 \
				-rgba 0xff000060
			for {set pos 0} {$pos < $num_samples} {incr pos} {
				osd create rectangle scc_viewer.$device.$chan.$pos \
					-x $pos \
					-y [expr {$channel_height / 2}] \
					-w 2 \
					-z 2 \
					-rgba 0xffffffb0
			}
		}
		incr number
		set offset 10
	}
	set machine_switch_trigger_id [after machine_switch [namespace code scc_viewer_reset]]
}

proc update_scc_viewer {} {
	variable scc_viewer_active
	variable scc_devices
	variable num_channels
	variable num_samples
	variable vertical_downscale_factor
	variable channel_height
	variable frame_trigger_id
	variable volume_address

	if {!$scc_viewer_active} return

	foreach device $scc_devices {
		binary scan [debug read_block "$device SCC" 0 224] c* scc_regs
		for {set chan 0} {$chan < $num_channels} {incr chan} {
			for {set pos 0} {$pos < $num_samples} {incr pos} {
				set scc_wave_new [expr {[get_scc_wave [lindex $scc_regs [expr {($chan * $num_samples) + $pos}]]] / $vertical_downscale_factor}]
					osd configure scc_viewer.$device.$chan.$pos \
						-h $scc_wave_new
			}
			set volume [expr {[lindex $scc_regs [expr {$volume_address + $chan}]] * 4}]
			osd configure scc_viewer.$device.$chan.volume \
				-h $volume \
				-y [expr {($channel_height - $volume) / 2}]
		}
	}
	# set frame_trigger_id [after frame [namespace code {puts [time update_scc_viewer]}]];# for profiling
	set frame_trigger_id [after time 0.05 [namespace code update_scc_viewer]]
}

proc get_scc_wave {sccval} {
	expr {-($sccval < 128 ? $sccval : $sccval - 256)}
}

proc scc_viewer_reset {} {
	variable scc_viewer_active
	if {!$scc_viewer_active} {
		error "Please fix a bug in this script!"
	}
	toggle_scc_viewer
	toggle_scc_viewer
}

proc toggle_scc_viewer {} {
	variable scc_viewer_active
	variable machine_switch_trigger_id
	variable frame_trigger_id

	if {$scc_viewer_active} {
		after cancel $machine_switch_trigger_id
		after cancel $frame_trigger_id
		set scc_viewer_active false
		osd destroy scc_viewer
	} else {
		scc_viewer_init
		set scc_viewer_active true
		update_scc_viewer
	}
	return ""
}

proc init {} {
	variable select_device
	update_device_list

	set_scc_wave $select_device 0 3
	set_scc_wave $select_device 1 2
	set_scc_wave $select_device 2 3
}

proc update1 {} {
	variable latch
	set latch $::wp_last_value
}

proc update2 {} {
	variable latch
	variable regs
	variable select_device

	set reg [expr {($latch == -1) ? $latch : [lindex $regs $latch]}]
	set val $::wp_last_value
	if {$latch == 7} {set val [expr {($val ^ 0x07) & 0x07}]}
	if {$reg != -1} {
		if {[catch {debug write "$select_device SCC" $reg $val}]} {
			# device gone? Let's deactivate
			toggle_psg2scc
		}
	}
}

proc toggle_psg2scc {} {
	variable active
	variable cur_wp1
	variable cur_wp2
	variable select_device

	if {!$active} {
		init
		set active true
		set cur_wp1 [debug set_watchpoint write_io 0xa0 1 {scc_toys::update1}]
		set cur_wp2 [debug set_watchpoint write_io 0xa1 1 {scc_toys::update2}]
		return "Activated."
	} else {
		debug remove_watchpoint $cur_wp1
		debug remove_watchpoint $cur_wp2
		catch { ;# may fail if device is gone
			debug write "$select_device SCC" 0xaf 0
		}
		set active false
		return "Deactivated."
	}
}

proc set_scc_form {device channel wave} {
	set base [expr {$channel * 32}]
	for {set i 0} {$i < 32} {incr i} {
		debug write "$device SCC" [expr {$base + $i}] "0x[string range $wave [expr {$i * 2}] [expr {$i * 2 + 1}]]"
	}
}

proc set_scc_wave {device channel form} {
	switch $form {
		0 { #Saw Tooth
			set_scc_form $device $channel "fff7efe7dfd7cfc7bfb7afa79f978f877f776f675f574f473f372f271f170f07"
		}
		1 { #Square
			set_scc_form $device $channel "7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f80808080808080808080808080808080"
		}
		2 { #Triangle
			set_scc_form $device $channel "7f7060504030201000f0e0d0c0b0a0908090a0b0c0d0e0f00010203040506070"
		}
		3 { #Sin Wave
			set_scc_form $device $channel "001931475A6A757D7F7D756A5A47311900E7CFB9A6968B8380838B96A6B9CFE7"
		}
		4 { #Organ
			set_scc_form $device $channel "0070502050703000507F6010304000B0106000E0F000B090C010E0A0C0F0C0A0"
		}
		5 { #SAWWY001
			set_scc_form $device $channel "636E707070705F2198858080808086AB40706F8C879552707052988080808EC1"
		}
		6 { #SQROOT01
			set_scc_form $device $channel "00407F401001EAD6C3B9AFA49C958F8A86838183868A8F959CA4AFB9C3D6EAFF"
		}
		7 { #SQROOT01
			set_scc_form $device $channel "636E707070705F2198858080808086AB40706F8C879552707052988080808EC1"
		}
		8 { #DYERVC01
			set_scc_form $device $channel "00407F4001C081C001407F4001C0014001E0012001F0011001FFFFFFFF404040"
		}
		9 { #SPACY
			set_scc_form $device $channel "808ea0c0e000203f3e3c3a373129201c1000e6c0d000203f10e080c000200090"
		}
	}
}

#SCC editor/copier
proc toggle_scc_editor {} {
	variable select_device

	if {![osd exists scc_viewer]} {toggle_scc_viewer}

	# If exists destory/reset and exit
	if {[osd exists scc]} {
		osd destroy scc
		osd destroy selected
		# Let's assume the user doesn't have the SCC Viewer active
		toggle_scc_viewer
		deactivate_input_layer scc_editor
		return ""
	}

	bind -layer scc_editor "mouse button1 down" {scc_toys::checkclick}
	activate_input_layer scc_editor

	osd create rectangle scc \
		-x 200 -y 100 -h 256 -w 256 \
		-rgba "0x0044aa80 0x2266dd80 0x0055cc80 0x44aaff80" \
		-borderrgba 0xffffffff -bordersize 1
	for {set i 0} {$i < 32} {incr i} {
		osd create rectangle scc.slider$i -x [expr {$i * 8}] -y 0 -h 255 -w 8 -rgba 0x0000ff80
		osd create rectangle scc.slider$i.val -x 0 -y 127 -h 1 -w 8 -rgba 0xffffff90
	}

	for {set i 0} {$i < 32} {incr i} {
		osd create rectangle "scc.hline$i" -x [expr {$i * 8 - 1}] -y 0 -h 255 -w 1 -rgba 0xffffff60
		osd create rectangle "scc.vline$i" -x 0 -y [expr {$i * 8 - 1}] -h 1 -w 255 -rgba 0xffffff60
	}

	osd create rectangle "scc.hmid1" -x 63 -y 0 -h 255 -w 1 -rgba 0xff000080
	osd create text      "scc.hmid1.text" -x -2 -y -12 -text "7" -size 8 -rgba 0xffffffff

	osd create rectangle "scc.hmid2" -x 127 -y 0 -h 255 -w 1 -rgba 0xffffffff
	osd create text      "scc.hmid2.text" -x -5 -y -12 -text "15" -size 8 -rgba 0xffffffff

	osd create rectangle "scc.hmid3" -x 191 -y 0 -h 255 -w 1 -rgba 0xff000080
	osd create text      "scc.hmid3.text" -x -5 -y -12 -text "23" -size 8 -rgba 0xffffffff

	osd create text      "scc.hline0.text" -x 0 -y -12 -text "0" -size 8 -rgba 0xffffffff
	osd create text      "scc.hline31.text" -x 0 -y -12 -text "31" -size 8 -rgba 0xffffffff

	osd create rectangle "scc.vmid1" -x 0 -y 63 -h 1 -w 255 -rgba 0xff000080
	osd create text      "scc.vmid1.text" -x -20 -y -4 -text "+64" -size 8 -rgba 0xffffffff

	osd create rectangle "scc.vmid2" -x 0 -y 127 -h 1 -w 255 -rgba 0xffffffff
	osd create text      "scc.vmid2.text" -x -10 -y -4 -text "0" -size 8 -rgba 0xffffffff

	osd create rectangle "scc.vmid3" -x 0 -y 191 -h 1 -w 255 -rgba 0xff000080
	osd create text      "scc.vmid3.text" -x -18 -y -4 -text "-64" -size 8 -rgba 0xffffffff

	osd create text      "scc.vline0.text" -x -25 -y 0 -text "+128" -size 8 -rgba 0xffffffff
	osd create text      "scc.vline31.text" -x -22 -y 0 -text "-128" -size 8 -rgba 0xffffffff

	osd create rectangle selected

	return ""
}

proc checkclick {} {
	variable scc_devices
	variable select_device
	variable select_device_chan

	#check editor matrix
	for {set i 0} {$i < 32} {incr i} {
		lassign [osd info "scc.slider$i" -mousecoord] x y
		if {($x >= 0 && $x <= 1) && ($y >= 0 && $y <= 1)} {
			debug write "$select_device SCC" [expr {$select_device_chan * 32 + $i}] [expr {int(255 * $y - 128) & 0xff}]
			osd configure scc.slider$i.val \
				-y [expr {$y * 255}] \
				-h [expr {128 - ($y * 255)}]
		}
	}

	#check scc viewer channels
	foreach device $scc_devices {
		for {set i 0} {$i < 5} {incr i} {
			lassign [osd info "scc_viewer.$device.$i" -mousecoord] x y
			if {($x >= 0 && $x <= 1) && ($y >= 0 && $y <= 1)} {
				#store device and channel picked from the SCC_viewer in memory
				set select_device $device
				set select_device_chan $i

				set abs_x [osd info "scc_viewer.$device" -x]
				set sel_h [osd info "scc_viewer.$device.$i" -h]
				set sel_w [osd info "scc_viewer.$device.$i" -w]
				set sel_x [osd info "scc_viewer.$device.$i" -x]
				set sel_y [osd info "scc_viewer.$device.$i" -y]

				osd configure selected \
					-x [expr {int($sel_x) + $abs_x}] \
					-y [expr {int($sel_y)}] \
					-w [expr {$sel_w + 4}] \
					-h [expr {$sel_h + 4}] \
					-z 1 \
					-rgba 0xff0000ff

				set base [expr {$i * 32}]
				for {set q 0} {$q < 32} {incr q} {
					set sccwave_new [get_scc_wave [debug read "$device SCC" [expr {$base + $q}]]]
					set sccwave_old [osd info scc.slider$q.val -h]
					osd configure scc.slider$q.val \
						-y [expr {128 + $y}] \
						-h $sccwave_new
				}
			}
		}
	}
}

proc get_val_matrix_column {sccval} {
	expr {$sccval < 0 ? $sccval + 256 : $sccval}
}

proc get_scc_string_from_matrix {name} {
	set sccstring ""
	set outputfile "$name"
	set output [open $outputfile "w"]

	for {set i 0} {$i < 32} {incr i} {
		set a [format %02x [get_val_matrix_column [expr {int([osd info scc.slider$i.val -h])}]]]
		set sccstring [concat $sccstring$a]
	}

	close $output

	puts "$outputfile writen to $name"
	return $sccstring
}

namespace export toggle_scc_editor
namespace export toggle_psg2scc
namespace export set_scc_wave
namespace export toggle_scc_viewer

} ;# namespace scc_toys

namespace import scc_toys::*
