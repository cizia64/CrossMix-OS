set_help_text toggle_freq "Switch the VDP between PAL (50 Hz)/NTSC (60 Hz)."

proc toggle_freq {} {
	vdpreg 9    [expr {[vdpreg 9   ] ^ 2}]
	poke 0xFFE8 [expr {[peek 0xFFE8] ^ 2}]

	set freq [expr {([vdpreg 9] & 2) ? 50 : 60}]
	osd::display_message "Frequency set to $freq Hz" info
}
