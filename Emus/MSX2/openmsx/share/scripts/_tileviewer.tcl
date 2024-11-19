namespace eval tileviewer {

proc checkclick {} {

	if {![osd exists tile_viewer]} {
		deactivate_input_layer tileviewer
		return
	}

	#check editor matrix
	# TODO instead of checking each cell in the matrix, calculate the cell from
	#      the mouse coordinates in the whole matrix
	for {set xm 0} {$xm < 8} {incr xm} {
		for {set ym 0} {$ym < 8} {incr ym} {
			lassign [osd info "tile_viewer.matrix.${xm}_${ym}" -mousecoord] x y
			if {($x >= 0 && $x <= 1) && ($y >= 0 && $y <= 1)} {
				# TODO we shouldn't use the state from the OSD elements (all OSD info commands),
				#      instead we should vpeek from VRAM and recalculate the vram address

				#lets chop this up in small pieces
				set fc [osd info tile_viewer.fc${ym} -rgba]
				set bc [osd info tile_viewer.bc${ym} -rgba]
				set tc [osd info tile_viewer.matrix.${xm}_${ym} -rgba]

				#toggle switch
				osd configure tile_viewer.matrix.${xm}_${ym} -rgba [expr {($fc == $tc) ? $bc : $fc}]
				set tile_add_val 0
				for {set i 0} {$i < 8} {incr i} {
					if {[osd info tile_viewer.matrix.${i}_${ym} -rgba] == $bc} {
						incr tile_add_val [expr {0x80 >> $i}]
					}
				}

				vpoke [osd info tile_viewer.matrix.text$ym -text] $tile_add_val
				return
			}
		}
	}
}

proc view_tile {tile} {

	bind -layer tileviewer "mouse button1 down" {tileviewer::checkclick}
	activate_input_layer tileviewer

	set addr [expr {$tile * 8}]

	osd destroy tile_viewer
	osd create rectangle tile_viewer -x 30 -y 30 -h 180 -w 330 -rgba 0x00007080
	osd_sprite_info::draw_matrix "tile_viewer.matrix" 90 24 18 8 1
	osd create text tile_viewer.text -x 0 -y 0 -size 20 -text "Tile: $tile" -rgba 0xffffffff

	for {set i 0} {$i < 16} {incr i} {
		lassign [split [getcolor $i] {}] r g b
		set rgbval($i) [expr {($r << (5 + 16)) + ($g << (5 + 8)) + ($b << 5)}]
	}

	# Build colors
	set color_base   [expr {$addr + ((([vdpreg 10] << 8 | [vdpreg 3]) << 6) & 0x1e000)}]
	set pattern_base [expr {$addr + (([vdpreg 4] & 0x3c) << 11)}]
	for {set i 0} {$i < 8} {incr i} {
		if {[get_screen_mode] != 1} {
			set col [vpeek [expr {$color_base + $i}]]
		} else {
			set col 0xf0
		}

		set bg [expr {($col & 0xf0) >> 4}]
		set fc [expr {$col & 0x0f}]
		osd create rectangle tile_viewer.bc$i -x 242 -w 16 -y [expr {24 + $i * 18}] -h 16 -rgb $rgbval($bg) -bordersize 1 -borderrgba 0xffffff80
		osd create rectangle tile_viewer.fc$i -x 260 -w 16 -y [expr {24 + $i * 18}] -h 16 -rgb $rgbval($fc) -bordersize 1 -borderrgba 0xffffff80

		osd create text tile_viewer.matrix.text$i  -x -50 -y [expr {$i * 18}] -text [format 0x%4.4x [expr {$pattern_base + $i}]] -rgba 0xffffffff
		osd create text tile_viewer.matrix.color$i -x 188 -y [expr {$i * 18}] -text [format 0x%2.2x $col] -rgba 0xffffffff
	}

	# Build patterns
	for {set y 0} {$y < 8} {incr y} {

		set pattern [vpeek [expr {$pattern_base + $y}]]
		set mask 0x80
		set bc [osd info tile_viewer.bc$y -rgba]
		set fc [osd info tile_viewer.fc$y -rgba]
		for {set x 0} {$x < 8} {incr x} {
			osd configure tile_viewer.matrix.${x}_${y} -rgba [expr {($pattern & $mask) ? $bc : $fc}] -bordersize 1 -borderrgba 0xffffff80
			set mask [expr {$mask >> 1}]
		}
	}
}

proc view_all_tiles {} {
	if {![osd exists all_tiles]} {

		osd create rectangle all_tiles -x 0 -y 0 -h 255 -w 255 -rgba 0xff0000ff

		for {set x 0} {$x < 256} {incr x} {
			for {set y 0} {$y < 192} {incr y} {
				osd create rectangle all_tiles.${x}_${y} -x $x -y $y -h 1 -w 1
			}
		}
	}

	if {[get_screen_mode] != 2} {
		for {set x 0} {$x < 256} {incr x} {
			for {set y 0} {$y < 192} {incr y} {
				osd configure all_tiles.${x}_${y} -rgb 0xffffff
			}
		}
		return
	}

	for {set i 0} {$i < 16} {incr i} {
		lassign [split [getcolor $i] {}] r g b
		set rgbval($i) [expr {($r << (5 + 16)) + ($g << (5 + 8)) + ($b << 5)}]
	}

	set color_addr   [expr {(([vdpreg 10] << 8 | [vdpreg 3]) << 6) & 0x1e000}]
	set pattern_addr [expr {([vdpreg 4] & 0x3c) << 11}]
	for {set y 0} {$y < 192} {incr y 8} {
		for {set x 0} {$x < 256} {incr x 8} {
			set ypos $y
			for {set yt 0} {$yt < 8} {incr yt} {
				set pattern [vpeek $pattern_addr]
				set col     [vpeek $color_addr]
				incr pattern_addr
				incr color_addr

				set bc [expr {$col >> 4}]
				set fc [expr {$col & 0x0f}]

				set mask 0x80
				set xpos $x
				for {set xt 0} {$xt < 8} {incr xt} {
					osd configure all_tiles.${xpos}_${ypos} -rgb $rgbval([expr {($pattern & $mask) ? $bc : $fc}])
					set mask [expr {$mask >> 1}]
					incr xpos
				}
				incr ypos
			}
		}
	}
}

proc hide_all_tiles_viewer {} {
	catch {osd destroy all_tiles}
	return ""
}

proc hide_tile_viewer {} {
	catch {osd destroy tile_viewer}
	return ""
}

set_help_text view_tile\
{Experimental tile viewer. Shows the tile (in pattern modes) with the given
number. Hide the viewer with hide_tile_viewer. In the viewer, you can toggle
pixels between fore- and background colors with a mouse click.}

set_help_text hide_tile_viewer\
{Hide the tile viewer you summoned with the view_tile command.}
namespace export view_tile
namespace export hide_tile_viewer

# for now do not expose the all tile viewer, as it is extremely slow

} ;# namespace tileviewer

namespace import tileviewer::*
