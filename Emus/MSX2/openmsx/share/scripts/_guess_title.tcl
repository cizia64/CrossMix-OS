namespace eval guess_title {

set_help_text guess_title \
{Guess the title of the currently running software. Remember... it's only a guess! It will be wrong some times. (But it will be right in many cases.)
}

# Here are some cases worth to consider and test.

# * FM-PAC as extension and a ROM game slot 2. You don't want to get the FM-PAC
#   returned when it's used as FM module, but you do when you did _FMPAC and use
#   the internal software of it.
# * Rollerball runs in page 2 (when using the proper ROM type)
# * Philips Music Module, start up with ESC. You don't want to return the ROM
#   as 'running software', but when you did not press ESC, you do.
# * Koei games like Teitoku no Ketsudan. In combination with an FM-PAC in slot
#   1. This games seems to run from RAM mostly.
# * Tape converted to cart. Runs in RAM.
# * SCC extension in combination with a disk game/demo. Runs with an empty ROM
#   which you don't want to return as title.
# * Sony HB-75P with internal software (Personal Data Bank). Runs in page 2.
# * MSX-DOS
# * MSX-DOS 2 (all pages are RAM)

# this one checks on the checkpage for external or internal software
proc guess_rom_device_z80space {internal checkpage} {
	lassign [get_selected_slot $checkpage] ps ss
	if {$ss eq "X"} {set ss 0}
	set incorrectslottype [machine_info isexternalslot $ps $ss]
	if {$internal} {
		set incorrectslottype [expr {!$incorrectslottype}]
	}
	if {$incorrectslottype} {
		foreach device [machine_info slot $ps $ss $checkpage] {
			set type [dict get [machine_info device $device] "type"]
			# try to ignore RAM devices
			if {$type ne "RAM" && $type ne "MemoryMapper" && $type ne "PanasonicRAM"} {
				return $device
			}
		}
	}
	return ""
}

proc guess_rom_device_nonextension {} {
	set system_rom_paths [filepool::get_paths_for_type system_rom]
	# Loop over all external slots which contain a ROM, return the first
	# which is not located in one of the systemrom filepools.
	for {set ps 0} {$ps < 4} {incr ps} {
		for {set ss 0} {$ss < 4} {incr ss} {
			if {![machine_info isexternalslot $ps $ss]} continue
			foreach device [machine_info slot $ps $ss 1] {
				set path ""
				catch {set path [dict get [machine_info device $device] "filename"]}
				if {$path eq ""} continue
				set ok 1
				foreach syspath $system_rom_paths {
					if {[string first $syspath $path] == 0} {
						set ok 0; break
					}
				}
				if {$ok} {return $device}
			}
		}
	}
	return ""
}

proc guess_rom_device_naive {} {
	for {set ps 0} {$ps < 4} {incr ps} {
		for {set ss 0} {$ss < 4} {incr ss} {
			if {[machine_info isexternalslot $ps $ss]} {
				set device_list [list]
				foreach device [machine_info slot $ps $ss 1] {
					# try to ignore RAM devices
					set type [dict get [machine_info device $device] "type"]
					if {$type ne "RAM" && $type ne "MemoryMapper" && $type ne "PanasonicRAM"} {
						lappend device_list $device
					}
				}
				if {[llength $device_list] != 0} {
					return $device_list
				}
			}
		}
	}
	return ""
}

proc guess_disk_title {drive_name} {
	# check name of the diskimage (remove directory part and extension)
	set disk ""
	catch {set disk [lindex [$drive_name] 1]}
	return [file rootname [file tail $disk]]
}

proc guess_cassette_title {} {
	# check name of the cassette image (remove directory part and extension)
	set cassette ""
	catch {set cassette [lindex [cassetteplayer] 1]}
	return [file rootname [file tail $cassette]]
}

proc guess_title {{fallback ""}} {
	# first try to see what is actually mapped in Z80 space
	# that is often correct, if it gives a result...
	# but it doesn't give a result for ROMs that copy themselves to RAM
	# (e.g. Koei games, tape games converted to ROM, etc.).
	set result [guess_rom_device_z80space false 1]
	if {$result ne ""} {return [rom_device_to_title $result]}

	# then try disks
	# games typically run from drive A, almost never from another drive
	set title [guess_disk_title "diska"]
	if {$title ne ""} {return $title}

	# then try cassette
	set title [guess_cassette_title]
	if {$title ne ""} {return $title}

	# if that doesn't give a result, try non extension devices
	set result [guess_rom_device_nonextension]
	if {$result ne ""} {return [rom_device_to_title $result]}

	# if that doesn't give a result, just return the first thing we find in
	# an external slot
	# ... this doesn't add much to the nonextension version
#	set result [guess_rom_device_naive]

	# perhaps we should simply return internal software if nothing found yet
	# Do page 1 last, because BASIC is in there
	set result [guess_rom_device_z80space true 3]
	if {$result ne ""} {return [rom_device_to_title $result]}
	set result [guess_rom_device_z80space true 2]
	if {$result ne ""} {return [rom_device_to_title $result]}
	set result [guess_rom_device_z80space true 1]
	if {$result ne ""} {return [rom_device_to_title $result]}

	# guess failed, return fallback
	return $fallback
}

proc rom_device_to_title {device} {
	set result $device
	if {[string tolower [file extension $device]] in [list .rom .ri .mx1 .mx2]} {
		set result [string totitle [file rootname $device]]
	}
	return $result
}

# use this proc if you only want to guess ROM titles
proc guess_rom_title {} {
	return [rom_device_to_title [guess_rom_device]]
}

proc guess_rom_device {} {
	set result [guess_rom_device_z80space false 1]
	if {$result ne ""} {return $result}

	# if that doesn't give a result, try non extension devices
	set result [guess_rom_device_nonextension]
	if {$result ne ""} {return $result}

	# if that doesn't give a result, just return the first thing we find in
	# an external slot (but not RAM)
	set result [guess_rom_device_naive]
	return $result
}

namespace export guess_title
namespace export guess_rom_title
namespace export guess_rom_device

} ;# namespace guess_title

namespace import guess_title::*
