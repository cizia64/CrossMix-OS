set_help_text rom_info\
{Prints information about the given ROM device, coming from the software
database. If no argument is given, the first found (external) ROM device is
shown.}

namespace eval rom_info {

proc tab {args} {
	set result [list]

	foreach device [machine_info device] {
		if {[dict get [machine_info device $device] "type"] eq "ROM"} {
			lappend result $device
		}
	}
	return $result
}

set_tabcompletion_proc rom_info [namespace code tab]

proc getlist_rom_info {{romdevice ""}} {
	if {$romdevice eq ""} {
		set romdevice [guess_rom_device]
		if {$romdevice eq ""} {
			error "No (external) ROM device found"
		}
	}

	if {[catch {set device_info [machine_info device $romdevice]}]} {
		error "No such device: $romdevice"
	}

	set device_type [dict get $device_info "type"]
	if {$device_type ne "ROM"} {
		error [format "Device is not of type ROM, but %s" $device_type]
	}

	set filename [dict get $device_info "filename"]

	set slotname ""
	set slot ""
	foreach slotcmd [info command cart?] {
		if {[lindex [$slotcmd] 1] eq $filename} {
			set slotname [string index $slotcmd end]
			set slotinfo [machine_info external_slot slot$slotname]
			set slotname [string toupper $slotname]
			set slot [lindex $slotinfo 0]
			set subslot [lindex $slotinfo 1]
			if {$subslot ne "X"} {
				append slot "-$subslot"
			}
		}
	}

	set actualSHA1 [dict get $device_info "actualSHA1"]
	set originalSHA1 [dict get $device_info "originalSHA1"]

	set rominfo ""
	if {[catch {set rominfo [openmsx_info software $actualSHA1]}]} {
		# try original sha1 to get more info
		catch {set rominfo [openmsx_info software $originalSHA1]}
	}
	set softPatched [expr {$actualSHA1 ne $originalSHA1}]
	set mappertype [dict get $device_info "mappertype"]

	set title ""
	set company ""
	set country ""
	set year ""
	set status ""
	set remark ""

	dict with rominfo {
		if {[info exists original] && $original} {
			# this is an unmodified original dump
			set status [format "Unmodified dump (confirmed by %s)" $orig_type]
		} else {
			# not original or unknown
			set status "Unknown"
			if {[info exists orig_type]} {
				switch $orig_type {
					"broken" {
						set status "Bad dump (game is broken)"
					}
					"translated" {
						set status "Translated from original"
					}
					"working" {
						set status "Modified but confirmed working"
					}
				}
			}
		}
	}
	if {$softPatched} {
		set statusPrefix ""
		if {$status ne ""} {
			set statusPrefix " "
		}
		set status "$status${statusPrefix}(but patched by openMSX)"
	}

	return [list \
			"filename"	$filename \
			"title"		$title \
			"year"		$year \
			"company"	$company \
			"country"	$country \
			"status"	$status \
			"remark"	$remark \
			"mappertype"	$mappertype \
			"slotname"	$slotname \
			"slot"		$slot]
}

proc rom_info {{romdevice ""}} {
	set rominfo [rom_info::getlist_rom_info $romdevice]

	dict with rominfo {
		if {$slotname ne "" && $slot ne ""} {
			append result "Cart. slot: $slotname (slot $slot)\n"
		}
		if {$title ne ""} {
			append result "Title:      $title\n"
		} elseif {$filename ne ""} {
			append result "File:       $filename\n"
		}
		if {$year ne ""} {
			append result "Year:       $year\n"
		}
		if {$company ne ""} {
			append result "Company:    $company\n"
		}
		if {$country ne ""} {
			append result "Country:    $country\n"
		}
		if {$status ne ""} {
			append result "Status:     $status\n"
		}
		if {$remark ne ""} {
			append result "Remark:     $remark\n"
		}
		if {$mappertype ne ""} {
			append result "Mapper:     $mappertype\n"
		}
	}
	return $result
}

namespace export rom_info
namespace export getlist_rom_info

} ;# namespace rom_info

namespace import rom_info::*
