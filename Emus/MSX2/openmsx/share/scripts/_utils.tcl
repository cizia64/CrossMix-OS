# Several utility procs for usage in other scripts
# don't export anything, just use it from the namespace,
# because these scripts aren't useful for console users
# and should therefore not be exported to the global
# namespace.
#
# These procs are not specific to anything special,
# they could be useful in any script.
#
# Born to prevent duplication between scripts for common stuff.

namespace eval utils {

proc get_machine_display_name {{machineid ""}} {
	if {$machineid eq ""} {
		set machineid [machine]
	}
	if {$machineid eq ""} {
		return "<none>"
	}
	set config_name [${machineid}::machine_info config_name]
	return [get_machine_display_name_by_config_name $config_name]
}

proc get_machine_display_name_by_config_name {config_name} {
	return [get_display_name_by_config_name $config_name "machines"]
}

proc get_extension_display_name_by_config_name {config_name} {
	return [get_display_name_by_config_name $config_name "extensions"]
}

proc get_display_name_by_config_name {config_name type} {
	if {[catch {
		set names [openmsx_info $type $config_name]
		if {$type eq "machines"} {
			set keylist [list "manufacturer" "code"]
		} elseif {$type eq "extensions"} {
			set keylist [list "manufacturer" "code" "name"]
		} else {
			error "Unsupported type: $type"
		}
		set arglist [list]
		foreach key $keylist {
			if [dict exists $names $key] {
				set arg [dict get $names $key]
				if {$arg ne ""} {
					lappend arglist $arg
				}
			}
		}
		set result [join $arglist]
		# fallback if this didn't give useful results:
		if {$result eq ""} {
			set result $config_name
		}
	}]} {
		# hmm, XML file probably broken. Fallback:
		set result "$config_name (CORRUPT)"
	}
	return $result
}

proc get_machine_time {{machineid ""}} {
	if {$machineid eq ""} {
		set machineid [machine]
	}
	set err [catch {set mtime [${machineid}::machine_info time]}]
	if {$err} {
		return ""
	}
	return [format_time $mtime]
}

proc format_time {time} {
	format "%02d:%02d:%02d" [expr {int($time / 3600)}] [expr {int($time / 60) % 60}] [expr {int($time) % 60}]
}

proc format_time_subseconds {time} {
	format "%02d:%02d.%02d" [expr {int($time / 60)}] [expr {int($time) % 60}] [expr {int(fmod($time,1) * 100)}]
}

proc get_ordered_machine_list {} {
	lsort -dictionary [list_machines]
}

proc get_random_number {max} {
	expr {floor(rand() * $max)}
}

proc clip {min max val} {
	expr {($val < $min) ? $min : (($val > $max) ? $max : $val)}
}

# provides.... file completion. Currently has a small issue: it adds a space at
# after a /, which you need to erase to continue completing
proc file_completion {args} {
	set result [list]
	foreach i [glob -nocomplain -path [lindex $args end] *] {
		if {[file isdirectory $i]} {
			append i /
		}
		lappend result $i
	}
	return $result
}

# Replaces characters that are invalid in file names on the host OS or
# file system by underscores.
if {$::tcl_platform(platform) eq "windows"
		|| [string match *-dingux* $::tcl_platform(osVersion)]
		|| [string match *-trimui* $::tcl_platform(osVersion)]} {
	# Dingux is Linux, but runs on VFAT.
	variable _filename_clean_disallowed {[\x00-\x1f\x7f/\\?*:|"<>+\[\]]}
} else {
	# UNIX does allow 0x01-0x1f and 0x7f, but we consider them undesirable.
	variable _filename_clean_disallowed {[\x00-\x1f\x7f/]}
}
proc filename_clean {path} {
	variable _filename_clean_disallowed
	return [regsub -all $_filename_clean_disallowed $path _]
}

# Gets you a filename with numbers in it to avoid overwriting
# an existing file with the same name. Especially useful for
# cases with automatically generated filenames
proc get_next_numbered_filename {directory prefix suffix} {
	set pattern "${prefix}\[0-9\]\[0-9\]\[0-9\]\[0-9\]${suffix}"
	set files [glob -directory $directory -tails -nocomplain $pattern]
	if {[llength $files] == 0} {
		set num "0001"
	} else {
		set name [lindex [lsort $files] end]
		scan [string range $name [string length $prefix] end] "%4d" n
		if {$n == 9999} {
			error "Can't create new filename"
		}
		set num [format "%04d" [expr {$n + 1}]]
	}
	file join $directory "${prefix}${num}${suffix}"
}

namespace export get_machine_display_name
namespace export get_machine_display_name_by_config_name
namespace export get_extension_display_name_by_config_name
namespace export get_display_name_by_config_name
namespace export get_machine_time
namespace export format_time
namespace export get_ordered_machine_list
namespace export get_random_number
namespace export clip
namespace export file_completion
namespace export filename_clean
namespace export get_next_numbered_filename

} ;# namespace utils

# Don't import in global namespace, these are only useful in other scripts.
