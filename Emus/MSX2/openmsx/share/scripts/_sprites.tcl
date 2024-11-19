#attributes
#expr {([vdpreg 11] << 15) + (([vdpreg 5] & 0xf8) << 7)}

namespace eval osd_sprite_info {

#todo: more sprite info / better layout (sprite mode/ hex values/ any other info)

variable title_pos 0
variable max_sprites 0

proc sprite_viewer {} {
	bind -layer sprite_viewer "keyb LEFT"   -repeat {osd_sprite_info::sprite_viewer_action 1}
	bind -layer sprite_viewer "keyb RIGHT"  -repeat {osd_sprite_info::sprite_viewer_action 2}
	bind -layer sprite_viewer "keyb ESCAPE" -repeat {osd_sprite_info::sprite_viewer_hide}
	bind -layer sprite_viewer "keyb SPACE"  -repeat {osd_sprite_info::sprite_viewer_action 0}
	activate_input_layer sprite_viewer

	osd create rectangle sprite_viewer -x 5 -y 100 -w 128 -h 190 -rgba 0x00000080
	osd create rectangle sprite_viewer.title -x 0 -y 15 -w 128 -h 32 -rgba 0x0000ff80 -clip on
	osd create text sprite_viewer.title.text -x 24 -text "" -size 18 -rgba 0xffffffff
	osd create text sprite_viewer.index -x 70 -y 38 -text "" -size 8 -rgba 0xffffffff
	osd create text sprite_viewer.refresh -x 8 -y 170 -size 8 -text "\[Space\] Refresh Sprite" -rgba 0xffffffff
	osd create text sprite_viewer.escape -x 8 -y 180 -size 8 -text "\[Escape\] to Exit Viewer" -rgba 0xffffffff

	sprite_viewer_action 0
}

proc sprite_viewer_action {action} {
	variable title
	variable title_pos
	variable max_sprites

	if {$action == 1} {incr title_pos -1}
	if {$action == 2} {incr title_pos  1}

	if {$title_pos > $max_sprites} {set title_pos 0}
	if {$title_pos < 0} {set title_pos $max_sprites}

	#show sprite matrix
	show_sprite $title_pos

	#fade/ease
	osd configure sprite_viewer.title.text -text "Sprite $title_pos" -fadeCurrent 0
	osd configure sprite_viewer.index      -text "In mem: $max_sprites"
	ease_text sprite_viewer.title.text 0 $action
}

proc sprite_viewer_hide {} {
	osd destroy sprite_viewer
	deactivate_input_layer sprite_viewer
}

proc ease_text {osd_object {frame_render 0} {action 0}} {
	#Ease in length
	set x 16

	#Intro Fade
	if {$frame_render == 0} {
	   osd configure $osd_object -x $x -fadeTarget 1 -fadePeriod 0.25
	}

	if {$frame_render > $x} {
		#leave routine
		return ""
	}

	#ease in
	if {$action == 2} {
		osd configure $osd_object -x [expr {$frame_render - $x}]
	} else {
		osd configure $osd_object -x [expr {$x - $frame_render}]
	}

	incr frame_render 4

	#call same function
	after realtime 0.05 [namespace code [list ease_text $osd_object $frame_render $action]]
}

proc show_sprite {sprite} {
	variable max_sprites

	set sprite_size [expr {([vdpreg 1] & 2) ? 16 : 8}]
	set factor [expr {($sprite_size == 8) ? 1 : 4}]
	set max_sprites [expr {(256 / $factor) - 1}]
	if {($sprite > $max_sprites) || ($sprite < 0)} {
		error "Please choose a value between 0 and $max_sprites"
	}

	osd destroy sprite_viewer.sprite_osd
	draw_matrix "sprite_viewer.sprite_osd" 7 56 7 $sprite_size 1

	set addr [expr {([vdpreg 6] << 11) + ($sprite * $factor * 8)}]
	for {set y 0} {$y < $sprite_size} {incr y; incr addr} {
		set pattern [vpeek $addr]
		set mask [expr {($sprite_size == 8) ? 0x80 : 0x8000}]
		if {$sprite_size == 16} {
			set pattern [expr {($pattern << 8) + [vpeek [expr {$addr + 16}]]}]
		}
		for {set x 0} {$x < $sprite_size} {incr x} {
			if {$pattern & $mask} {
				osd configure sprite_viewer.sprite_osd.${x}_${y} -rgba 0xffffffff
			}
			set mask [expr {$mask >> 1}]
		}
	}
}

proc draw_matrix {matrixname x y blocksize matrixsize matrixgap} {
	osd create rectangle $matrixname \
		-x $x \
		-y $y \
		-h [expr {$matrixsize * $blocksize}] \
		-w [expr {$matrixsize * $blocksize}] \
		-rgba 0x00000040

	for {set x 0} {$x < $matrixsize} {incr x} {
		for {set y 0} {$y < $matrixsize} {incr y} {
			osd create rectangle $matrixname.${x}_${y} \
				-h [expr {$blocksize - $matrixgap}] \
				-w [expr {$blocksize - $matrixgap}] \
				-x [expr {$x * $blocksize}] \
				-y [expr {$y * $blocksize}] \
				-rgba 0x0000ff80
		}
	}

	return ""
}

namespace export sprite_viewer

} ;# namespace osd_menu

namespace import osd_sprite_info::*
