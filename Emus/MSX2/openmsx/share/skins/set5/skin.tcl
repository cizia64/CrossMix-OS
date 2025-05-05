# global settings
#
#    name         default   description
# ------------------------------------------------------------------------------
#  xbase             0       x-coord of bounding box for LEDs
#  ybase             0       y-coord
#  xwidth           16       width of images (used to calculate default positions)
#  yheight          16       height
#  xspacing         32       space between horizontally placed LEDs
#  yspacing         35                     vertically
#  horizontal        1       1 -> horizontal   0 -> vertical
#  fade_delay        5       time before LEDs start fading
#  fade_duration     5       time it takes to fade from opaque to transparent
#  position        default   chosen position, can be left/right/top/bottom/default
#                            Scripts *should* overrule the value 'default', but
#                            they *may* also overrule other values.
#
# per LED settings
#   default values are calcluated from the global settings
#   exact LED names are: power caps kana pause turbo FDD
#
#    name(<led>)             description
# ------------------------------------------------------------------------------
#  xcoord                     x-coord of LED in bounding box
#  ycoord                     y-coord
#  fade_delay_active          see global fade_delay setting
#  fade_delay_non_active      "
#  fade_duration_active       see global fade_delay setting
#  fade_duration_non_active   "
#  active_image               filename for LED image, default is <led>-on.png
#  non_active_image           "                                  <led>-off.png

set xwidth 32
set yheight 32
set xspacing 40
set yspacing 40
if {$position == "default"} { set position "bottom" }
