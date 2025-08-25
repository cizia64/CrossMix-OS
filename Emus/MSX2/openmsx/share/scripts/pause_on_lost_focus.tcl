namespace eval pause_on_lost_focus {

proc setting_changed {name1 name2 op} {
	if {$::pause_on_lost_focus} {
		bind_default "focus 0" "set pause 1"
		bind_default "focus 1" "set pause 0"
	} else {
		unbind_default "focus 0"
		unbind_default "focus 1"
	}
}

user_setting create boolean pause_on_lost_focus "pause emulation when the openMSX window loses focus" false
trace add variable ::pause_on_lost_focus write [namespace code setting_changed]

# initial setup (bind or unbind)
setting_changed pause_on_lost_focus "" write

}
