namespace eval osd_widgets {

set help_text \
{The command 'osd_widgets::msx_init' takes one parameter, this parameter will be used as
our base layer which will be scaled according to the MSX resultion adjusted for
'set adjust', 'scale factor' and 'horizontal_stretch'.

All these compensation factors ('set adjust', ...) can change over time. So it
is needed to 'regularly' (e.g. in a 'after frame' callback) re-adjust the msx
layer. This can be done with the 'osd_widgets::msx_update' proc.

Example: osd_widgets::msx_init baselayer
         osd create rectangle baselayer.box -x 10 -y 10 -h 16 -w 16 -rgb 0xffffff
         ...
         osd_widgets::msx_update baselayer

This will display a white 16x16 box at MSX location x,y == 10,10.}
set_help_text osd_widgets::msx_init   $help_text
set_help_text osd_widgets::msx_update $help_text

proc msx_init {name} {
	osd create rectangle $name -scaled true -alpha 0
	msx_update $name
}

proc msx_update {name} {
	# compensate for horizontal-stretch and set-adjust
	set hstretch $::horizontal_stretch
	set xsize   [expr {320.0 / $hstretch}]
	set xoffset [expr {($hstretch - 256) / 2 * $xsize}]
	set ysize 1
	set lines [expr {([vdpreg 9] & 128) ? 212 : 192}]
	set yoffset [expr {(240 - $lines) / 2 * $ysize}]
	set adjreg [vdpreg 18]
	set hadj [expr {(($adjreg & 15) ^ 7) - 7}]
	set vadj [expr {(($adjreg >> 4) ^ 7) - 7}]
	set xoffset [expr {$xoffset + $xsize * $hadj}]
	set yoffset [expr {$yoffset + $ysize * $vadj}]
	osd configure $name -x $xoffset -y $yoffset -w $xsize -h $ysize
}

set_help_text create_power_bar\
{The command 'osd_widgets::create_power_bar' supports the following parameters:
    -name == Name of the power bar
    -w == Width of the power bar (in pixels)
    -h == Height of the power bar
    -barcolor == Powerbar color
    -background == When power declines this color is shown
    -edgecolor == This is the edge color (try white when I doubt which color to use)

Colors must have the following hexadecimal format 0xRRGGBBAA.

The power bar is initially created outside the viewable area, so we need to invoke
the 'update_power_bar' command to make it visible. Use 'hide_power_bar' to
remove it again.}

set_help_text update_power_bar\
{The command 'update_power_bar' uses the following parameters:
    -name == Name of the power bar
    -x == vertical position of the power bar
    -y == horizontal position of the power bar
    -power == fill rate of the power bar in decimal percentages (10% == 0.1)
    -text == text to be printed above the power bar}

proc create_power_bar {name w h barcolor background edgecolor} {
	osd create rectangle $name        -rely 999 -relw $w -relh $h -rgba $background
	osd create rectangle $name.top    -x -1 -y   -1 -relw 1 -w 2 -h 1 -rgba $edgecolor
	osd create rectangle $name.bottom -x -1 -rely 1 -relw 1 -w 2 -h 1 -rgba $edgecolor
	osd create rectangle $name.left   -x -1         -w 1 -relh 1      -rgba $edgecolor
	osd create rectangle $name.right  -relx 1       -w 1 -relh 1      -rgba $edgecolor
	osd create rectangle $name.bar    -relw 1 -relh 1 -rgba $barcolor -z 18
	osd create text      $name.text   -x 0 -y -6 -size 4 -rgba $edgecolor
}

proc update_power_bar {name x y power text} {
	if {$power > 1.0} {set power 1.0}
	if {$power < 0.0} {set power 0.0}
	osd configure $name -relx $x -rely $y
	osd configure $name.bar -relw $power
	osd configure $name.text -text "$text"
}

proc hide_power_bar {name} {
	osd configure $name -rely 999
}


set_help_text toggle_fps \
{Enable/disable a frames per second indicator in the top-left corner of the screen.}

variable fps_after

proc toggle_fps {} {
	variable fps_after
	if {[info exists fps_after]} {
		after cancel $osd_widgets::fps_after
		osd destroy fps_viewer
		unset fps_after
	} else {
		osd create rectangle fps_viewer -x 5 -y 5 -z 0 -w 63 -h 20 -rgba 0x00000080
		osd create text fps_viewer.text -x 5 -y 3 -z 1 -rgba 0xffffffff
		proc fps_refresh {} {
			variable fps_after
			osd configure fps_viewer.text -text [format "%2.1fFPS" [openmsx_info fps]]
			set fps_after [after realtime .5 [namespace code fps_refresh]]
		}
		fps_refresh
	}
	return ""
}

variable bat_after

proc toggle_battery_level {} {
	variable bat_after
	if {[info exists bat_after]} {
		after cancel $osd_widgets::bat_after
		osd destroy bat_viewer
		unset bat_after
	} else {
		osd create rectangle bat_viewer -x 270 -y 5 -z 0 -w 45 -h 20 -rgba 0x00000080
		osd create text bat_viewer.text -x 5 -y 3 -z 1 -rgba 0xffffffff
		proc bat_refresh {} {
			variable bat_after
			set batteryfile "/sys/class/power_supply/axp2202-battery/capacity"
			set fp [open $batteryfile r]
			set battery_level [string trim [read $fp]]
			close $fp
			if {$battery_level < 100} {
				osd configure bat_viewer.text -text [format " %.0f%%" $battery_level]
			} else {
				osd configure bat_viewer.text -text [format "%.0f%%" $battery_level]
			}
			set bat_after [after realtime 1 [namespace code bat_refresh]]
		}
		bat_refresh
	}
	return ""
}

set_help_text osd_widgets::text_box\
{The 'osd_widgets::text_box' widget supports the same properties as a 'rectangle' widget with the following additions:
 -text: defines the text to be printed, can have multiple lines (separated by 'new line' characters).
 -textcolor: defines the color of the text
 -textsize: defines the font size of the text}

variable widget_handlers
variable opaque_duration   2.5
variable fade_out_duration 2.5
variable fade_in_duration  0.4

proc text_box {name args} {
	variable widget_handlers
	variable opaque_duration

	# Default values in case nothing is given
	set txt_color 0xffffffff
	set txt_size 6

	# Process arguments
	set rect_props [list]
	foreach {key val} $args {
		switch -- $key {
			-text     {set message $val}
			-textrgba {set txt_color $val}
			-textsize {set txt_size  $val}
			default   {lappend rect_props $key $val}
		}
	}

	if {$message eq ""} return

	# For handheld devices set minimal text size to 9
	#  TODO: does this belong here or at some higher level?
	if {($::scale_factor == 1) && ($txt_size < 9)} {
		set txt_size 9
	}

	# Destroy widget (if it already existed)
	osd destroy $name

	# Guess height of rectangle
	osd create rectangle $name {*}$rect_props -h [expr {4 + $txt_size}]

	osd create text $name.text -x 2 -y 2 -size $txt_size -rgb $txt_color \
		-text $message -wrap word -wraprelw 1.0 -wrapw -4

	# Adjust height of rectangle to actual text height (depends on newlines
	# and text wrapping).
	catch {
		lassign [osd info $name.text -query-size] x y
		osd configure $name -h [expr {4 + $y}]
	}

	# if the widget was still active, kill old click/opaque handler
	if {[info exists widget_handlers($name)]} {
		lassign $widget_handlers($name) click opaque
		after cancel $click
		after cancel $opaque
	}

	set click  [after "mouse button1 down" "osd_widgets::click_handler $name"]
	set opaque [after realtime $opaque_duration "osd_widgets::timer_handler $name"]
	set widget_handlers($name) [list $click $opaque]

	return ""
}

proc click_handler {name} {
	if {[osd::is_cursor_in $name]} {
		kill_widget $name
	}
	return ""
}

proc kill_widget {name} {
	variable widget_handlers

	lassign $widget_handlers($name) click opaque
	after cancel $click
	after cancel $opaque
	unset widget_handlers($name)
	osd destroy $name
}

proc timer_handler {name} {
	variable widget_handlers
	variable opaque_duration
	variable fade_out_duration
	variable fade_in_duration

	# clicking it might have killed it already
	if {![osd exists $name]} {
		return
	}

	# if already faded out... don't poll again and clean up
	if {[osd info $name -fadeCurrent] == 0.0} {
		kill_widget $name
		return
	}

	# If the cursor is over the widget, we fade-in fast and leave the widget
	# opaque for some time (= don't poll for some longer time). Otherwise
	# we fade-out slow and more quickly poll the cursor position.
	lassign $widget_handlers($name) click opaque
	if {[osd::is_cursor_in $name]} {
		osd configure $name -fadePeriod $fade_in_duration -fadeTarget 1.0
		set opaque [after realtime $opaque_duration "osd_widgets::timer_handler $name"]
	} else {
		osd configure $name -fadePeriod $fade_out_duration -fadeTarget 0.0
		set opaque [after realtime 0.25 "osd_widgets::timer_handler $name"]
	}
	set widget_handlers($name) [list $click $opaque]
}

proc volume_control {incr_val} {
	if {![osd exists volume]} {
		osd create rectangle volume -x 0 -y 0 -h 32 -w 320 -rgba 0x000000a0 -scaled true
		osd create rectangle volume.bar -x 16 -y 16 -h 8 -w 290 -rgba 0x000000c0 -borderrgba 0xffffffff -bordersize 1
		osd create rectangle volume.bar.meter -x 1 -y 1 -h 6 -w 288 -rgba "0x00aa33e8 0x00dd66e8 0x00cc55e8 0x00ff77e8"
		osd create text      volume.text -x 16 -y 3 -size 10 -rgba 0xffffffff
	}

	incr ::master_volume $incr_val
	if {$::master_volume == 0} {set ::mute on} else {set ::mute off}
	osd configure volume.bar.meter -w [expr {($::master_volume / 100.00) * 288}]
	osd configure volume.text -text [format "Volume: %03d" $::master_volume]
	osd configure volume -fadePeriod 5 -fadeTarget 0 -fadeCurrent 1
}

# only export stuff that is useful in other scripts or for the console user
namespace export toggle_fps
namespace export toggle_battery_level
namespace export msx_init
namespace export msx_update
namespace export box
namespace export text_box
namespace export create_power_bar
namespace export update_power_bar
namespace export hide_power_bar
namespace export volume_control

};# namespace osd_widgets

# only import stuff to global that is useful outside of scripts (i.e. for the console user)
namespace import osd_widgets::toggle_fps
namespace import osd_widgets::toggle_battery_level
namespace import osd_widgets::volume_control
