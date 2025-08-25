namespace eval cashandler {

user_setting create boolean fast_cas_load_hack_enabled \
"Whether you want to enable a hack that enables you to quickly load CAS files
with the cassetteplayer, without converting them to WAV first. This is not
recommended and several cassetteplayer functions will not work anymore (motor
control, position indication, size indication). Also note that this hack only
works when inserting cassettes when the MSX is already started up, not when
inserting them via the openMSX command line." false

variable old_value $::fast_cas_load_hack_enabled
variable hack_is_already_enabled false

proc set_hack {} {
	variable hack_is_already_enabled
	# example: turboR..
	# for now, ignore the commands... it's quite complex to
	# get this 100% water tight with adding/removing machines
	# at run time
	if {[catch "machine_info connector cassetteport"]} return
	
	if {$::fast_cas_load_hack_enabled && !$hack_is_already_enabled} {
		interp hide {} cassetteplayer
		interp alias {} cassetteplayer {} cashandler::tapedeck
		set hack_is_already_enabled true
		puts "Fast cas load hack installed."
	} elseif {!$::fast_cas_load_hack_enabled && $hack_is_already_enabled} {
		interp alias {} cassetteplayer {}
		interp expose {} cassetteplayer
		set hack_is_already_enabled false
		puts "Fast cas load hack uninstalled."
	}
}

proc setting_changed {name1 name2 op} {
	variable old_value

	if {$::fast_cas_load_hack_enabled != $old_value} {
		set_hack
		set old_value $::fast_cas_load_hack_enabled
	}
}

trace add variable ::fast_cas_load_hack_enabled write [namespace code setting_changed]

proc initial_set {} {
	if {$::fast_cas_load_hack_enabled} {
		set_hack
	}
}

after realtime 0 [namespace code initial_set]

} ;# namespace cashandler
