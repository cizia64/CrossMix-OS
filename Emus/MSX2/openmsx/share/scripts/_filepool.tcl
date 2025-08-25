namespace eval filepool {

set_help_text filepool \
{Manage filepool settings

  filepool list
    Shows the currently defined filepool entries.

  filepool add -path <path> -types <typelist> [-position <pos>]
    Add a new entry. Each entry must have a directory and a list of filetypes.
    Possible filetypes are 'system_rom', 'rom', 'disk' and 'tape'. Optionally
    you can specify the position of this new entry in the list of existing
    entries (by default new entries are added at the end).

  filepool remove <position>
    Remove the filepool entry at the given position.

  filepool reset
    Reset the filepool settings to the default values.
}

proc filepool_completion {args} {
	if {[llength $args] == 2} {
		return [list list add remove reset]
	}
	return [list -path -types -position system_rom rom disk tape]
}
set_tabcompletion_proc filepool [namespace code filepool_completion]


proc filepool {args} {
	set cmd [lindex $args 0]
	set args [lrange $args 1 end]
	switch -- $cmd {
		"list"   {filepool_list}
		"add"    {filepool_add {*}$args}
		"remove" {filepool_remove $args}
		"reset"  {filepool_reset}
		"default" {
			error "Invalid subcommand, expected one of 'list add remove reset', but got '$cmd'"
		}
	}
}

proc filepool_list {} {
	set result ""
	set i 1
	foreach pool $::__filepool {
		append result "$i: [dict get $pool -path]  \[[dict get $pool -types]\]\n"
		incr i
	}
	return $result
}

proc filepool_checktypes {types} {
	set valid [list "system_rom" "rom" "disk" "tape"]
	foreach type $types {
		if {$type ni $valid} {
			error "Invalid type, expected one of '$valid', but got '$type'"
		}
	}
}

proc filepool_add {args} {
	set pos [llength $::__filepool]
	set path ""
	set types ""
	foreach {name value} $args {
		if {$name eq "-position"} {
			set pos [expr {$value - 1}]
		} elseif {$name eq "-path"} {
			set path $value
		} elseif {$name eq "-types"} {
			filepool_checktypes $value
			set types $value
		} else {
			error "Unknown option: $name"
		}
	}
	if {($pos < 0) || ($pos > [llength $::__filepool])} {
		error "Value out of range: [expr {$pos + 1}]"
	}
	if {$path eq ""} {
		error "Missing -path"
	}
	if {$types eq ""} {
		error "Missing -types"
	}

	set newpool [dict create -path $path -types $types]
	if {$pos == [llength $::__filepool]} {
		lappend ::__filepool $newpool
	} else {
		set ::__filepool [lreplace $::__filepool $pos -1 $newpool]
	}
	return ""
}

proc filepool_remove {id} {
	if {($id < 1) || ($id > [llength $::__filepool])} {
		error "Value out of range: $id"
	}
	set idx [expr {$id - 1}]
	set ::__filepool [lreplace $::__filepool $idx $idx]
	return ""
}

proc filepool_reset {}  {
	unset ::__filepool
}

proc get_paths_for_type {type} {
	set result [list]
	foreach pool $::__filepool {
		set types [dict get $pool -types]
		if {$type in $types} {
			lappend result [dict get $pool -path]
		}
	}
	return $result
}

namespace export filepool

} ;# namespace filepool

namespace import filepool::*
