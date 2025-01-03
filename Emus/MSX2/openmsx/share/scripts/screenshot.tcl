namespace eval openmsx {

rename ::screenshot old_screenshot

proc screenshot {args} {
	set args2 [list]
	set sprites true
	foreach arg $args {
		if {$arg eq "-no-sprites"} {
			set sprites false
		} elseif {$arg eq "-guess-name"} {
			set base [utils::filename_clean [guess_title untitled]]
			if {$base ne ""} {lappend args2 -prefix "$base "}
		} else {
			lappend args2 $arg
		}
	}
	if {$sprites} {
		old_screenshot {*}$args2
	} else {
		# disable sprites, wait for one complete frame and take screenshot
		set orig_disable_sprites $::disablesprites
		set ::disablesprites true
		after frame [namespace code [list screenshot_helper1 $orig_disable_sprites $args2]]
	}
}
proc screenshot_helper1 {orig_disable_sprites args2} {
	after frame [namespace code [list screenshot_helper2 $orig_disable_sprites $args2]]
}
proc screenshot_helper2 {orig_disable_sprites args2} {
	# take screenshot and restore 'disablesprites' setting
	old_screenshot {*}$args2
	set ::disablesprites $orig_disable_sprites
}

namespace export screenshot

}; # namespace

namespace import openmsx::screenshot
