namespace eval reverse {

variable is_dingux [string match dingux "[openmsx_info platform]"]
variable is_trimui [string match trimui "[openmsx_info platform]"]
variable is_android [string match android "[openmsx_info platform]"]

variable default_auto_enable_reverse
if {$is_dingux || $is_trimui || $is_android} {
	set default_auto_enable_reverse "off"
} else {
	set default_auto_enable_reverse "gui"
}

proc after_switch {} {
	# enabling reverse could fail if the active machine is an 'empty'
	# machine (e.g. because the last machine is removed or because
	# you explictly switch to an empty machine)
	catch {
		if {$::auto_enable_reverse eq "on"} {
			auto_enable
		} elseif {$::auto_enable_reverse eq "gui"} {
			reverse_widgets::enable_reversebar false
		}
	}
	after machine_switch [namespace code after_switch]
}

} ;# namespace reverse


user_setting create string "auto_enable_reverse" \
{Controls whether the reverse feature is automatically enabled on startup.
Internally the reverse feature takes regular snapshots of the MSX state,
this has a (small) cost in memory and in performance. On small systems you
don't want this cost, so we don't enable the reverse feature by default.
Possible values for this setting:
  off   Reverse not enabled on startup
  on    Reverse enabled on startup
  gui   Reverse + reverse_bar enabled (see 'help toggle_reversebar')
} $reverse::default_auto_enable_reverse

user_setting create float "reversebar_fadeout_time" \
{Time it takes for the reverse bar to fade out when it's not in focus. Set to 0 for no fade out at all.
} 5.0 0.0 100.0

user_setting create boolean "auto_save_replay" \
{Enables automatically saving the current replay to filename specified \
in the setting "auto_save_replay_filename" with the interval specified \
in the setting "auto_save_replay_interval".
The file will keep being overwritten until you disable the auto save again.\
} false

user_setting create string "auto_save_replay_filename" \
{Filename of the replay file that will be saved to when auto_save_replay is \
enabled.
} "auto_save"

user_setting create float "auto_save_replay_interval" \
{If enabled, auto save the current replay every number of seconds that is \
specified with this setting.
} 30.0 0.01 100000.0

# TODO hack:
# The order in which the startup scripts are executed is not defined. But this
# needs to run after the load_icons script has been executed.
#
# It also needs to run after 'after boot' proc in the autoplug.tcl script. The
# reason is tricky:
#  - If this runs before autoplug, then the initial snapshot (initial snapshot
#    triggered by enabling reverse) does not contain the plugged cassette player
#    yet.
#  - Shortly after the autoplug proc runs, this will plug the cassetteplayer.
#    This plug command will be recorded in the event log. This is fine.
#  - The problem is that we don't serialize information for unplugged devices
#    ((only) in the initial snapshot, the cassetteplayer is not yet plugged). So
#    the information about the inserted tape is lost.

# As a solution/hack, we trigger this script at emutime=0. This is after the
# autoplug script (which triggers at 'after boot'. But also this is also
# triggered when openmsx is started via a replay file from the command line
# (in such case 'after boot' is skipped).

after realtime 0 {reverse::after_switch}
