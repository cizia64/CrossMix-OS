# Callback on read from uninitialized memory (UMR). Not enabled by default.
set_help_text umrcallback \
{This is an example of a UMR callback function. You can set the "umr_callback"
setting in openMSX to "umrcallback" and this function will be called whenever
openMSX detects a read from uninitialized memory. It might be a good idea to
go into 'debug break' mode in this callback, so that you can easily examine
what is going on which has caused the UMR.

 @param addr The absolute address in the RAM device.
 @param name The name of the RAM device.
}

proc umrcallback {addr name} {
	puts stderr [format "UMR detected in RAM device \"$name\", offset: 0x%04X, PC: 0x%04X" $addr [reg PC]]
}
#set umr_callback umrcallback


# Callback on changing the VDP command registers while a command is still in
# progress. Not enabled by default.
set_help_text vdpcmdinprogresscallback \
{This is an example of a vdpcmdinprogress callback function. To use it execute
    set vdpcmdinprogress_callback vdpcmdinprogresscallback
After changing that setting this proc will be called whenever openMSX detects a
write to a VDP command engine register while there's still a VDP command in
progress. Often this is an indication of a bug in the MSX program. This example
callback proc only prints the register number, the value that was being written
and the program counter. Feel free to write your own callback procs. For
example it might be a good idea to enter 'debug break' mode in your callback,
so that you can easily examine what is going on.

 @param reg The VDP command engine register number that was being written
            This is in range 0..14. Note that it's OK to write register 12
            while a command is in progress. So this callback will not be
            triggered for writes to register 12.
 @param val The value that was being written.
}

proc vdpcmdinprogresscallback {reg val} {
	puts stderr [format "Write to VDP command engine detected while there's still a command in progress: reg = %d, val = %d, PC = 0x%04X" [expr {$reg + 32}] $val [reg PC]]
}
#set vdpcmdinprogress_callback vdpcmdinprogresscallback


# Callback on setting invalid PSG port directions.
set psg_directions_warning_printed false
proc psgdirectioncallback {} {
	if {$::psg_directions_warning_printed} return
	set ::psg_directions_warning_printed true
	message {The running MSX software has set unsafe PSG port directions.
Real (older) MSX machines can get damaged by this.} warning
}
set invalid_psg_directions_callback psgdirectioncallback


# Callback on setting an invalid PPI mode.
set ppi_mode_warning_printed false
proc ppimodecallback {} {
	if {$::ppi_mode_warning_printed} return
	set ::ppi_mode_warning_printed true
	message {Invalid PPI mode selected. This is not yet correctly emulated. On a real MSX this will most likely hang.} warning
}
set invalid_ppi_mode_callback ppimodecallback


# Callback on DI;HALT.
proc dihaltcallback {} {
	set machine [machine_info type]
	if {[string match "MSX*" $machine] || $machine eq "SVI"} { # These machines do not use NMI.
		message "DI; HALT detected, which means a hang. You can just as well reset the machine now..." warning
	}
}
set di_halt_callback dihaltcallback


# Callback on too fast VRAM read/write, not enabled by default
proc warn_too_fast_vram_access {} {
	message [format "Too fast VRAM access PC=0x%04x Y-pos=%d" [reg PC] [machine_info VDP_msx_y_pos]] warning
}
proc debug_too_fast_vram_access {} {
	warn_too_fast_vram_access
	debug break
}
#set VDP.too_fast_vram_access_callback debug_too_fast_vram_access
#set VDP.too_fast_vram_access_callback warn_too_fast_vram_access

proc sensorkidportstatuscallback {port value} {
	message "Sensor Kid port $port has been [expr {$value ? "enabled" : "disabled"}]" info
}
proc sensorkidacquirecallback {port} {
	set time [machine_info time]
	switch $port {
		0 { # Sine
			return [expr {int(sin($time * 0.1) * 127.0) + 128}]
		}
		1 { # Sawtooth
			return [expr {int($time * 10.0) % 256}]
		}
		2 { # Triangle
			set t [expr {int($time * 4.0) % 512}]
			return [expr {($t > 255) ? (511 - $t) : $t}]
		}
		default {
			return 255
		}
	}
}
set sensor_kid_port_status_callback sensorkidportstatuscallback
set sensor_kid_acquire_callback     sensorkidacquirecallback


# show message (also) as OSD message
set message_callback osd::display_message
