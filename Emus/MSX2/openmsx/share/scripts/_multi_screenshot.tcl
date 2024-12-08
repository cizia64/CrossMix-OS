namespace eval multi_screenshot {

set_help_text multi_screenshot \
{Take multiple screenshots

Usage:
 multi_screenshot <num> [<base>]
}

proc multi_screenshot {num {base ""}} {
	multi_screenshot_helper 1 $num $base
	return ""
}

proc multi_screenshot_helper {acc max {base ""}} {
	if {$acc <= $max} {
		if {$base eq ""} {
			screenshot
		} else {
			screenshot -prefix $base
		}
		after frame "[namespace code multi_screenshot_helper] [expr {$acc + 1}] $max $base"
	}
}

namespace export multi_screenshot

} ;# namespace multi_screenshot

namespace import multi_screenshot::*
