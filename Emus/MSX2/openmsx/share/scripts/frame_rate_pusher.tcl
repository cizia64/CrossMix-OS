# This is a special script to force frame draws, even though there is nothing
# new to draw. Some platforms (like SDL on Android) require this to read input
# regularly. The value of 0.04 gives about 25 fps updates.

namespace eval frame_rate_pusher {

proc move_frp {} {
	osd configure frp -x [expr {1 - [osd info frp -x]}]
	after realtime 0.04 [namespace code move_frp]
}

if {[string match android "[openmsx_info platform]"]} {
	osd create rectangle frp -alpha 0 -w 1 -h 1 -x 0
	move_frp
}
}

