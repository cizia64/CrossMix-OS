set_help_text vdrive \
{v-drive functionality of blueMSX implemented in a Tcl script for openMSX
version 1.0

What does it do:
  It is a simple Tcl script that bound to a hotkey (f.i. F9+ALT) allows
  users to swap disks without using the commandconsole or Catapult for
  file selection. This is especially useful for games and demos that
  span over multiple disks.

Preparations:
1. If you have software that spans multiple disks, you have to name them
   according to the scheme: name+digit+extension for example [metal1.dsk,
   metal2.dsk, metal3.dsk]
   Of course they may all be compressed with gzip, so you'll end up with
   [metal1.dsk.gz, metal2.dsk.gz, metal3.dsk.gz].
   The script recognizes 'dsk', 'di1', 'di2', 'xsa' and 'dmk' extensions,
   with an optional '.gz' or '.zip' suffix.

2. bind the vdrive script to a hotkey, for instance type in the console:
     bind ALT+F9 "vdrive diska"
     bind ALT+F10 "vdrive diskb"
   vdrive will default to 'diska' when no drive parameter is specified.
   Note: the two bind commands above are already the default key bindings;
         you only need to execute them if you want a different key binding.

Using:
  While emulating an MSX, and the sofware asks for the next disk, simply
  press the hot-key. The script will select the next disk in the sequence.
  If the last disk is reached, the script will select the first disk
  again. So you actually are cycling through the entire disk set as shown
  in the diagram below

   _"disk1.dsk" => ALT+F9 => "disk2.dsk" => ALT+F9 => "disk3.dsk" _
  |                                                                |
   <= <= <= <= <= <= <= ALT+F9  <= <= <= <= <= <= <= <= <= <= <= <=


credits:
  original alt+f9 v-DRIVE idea by the blueMSX crew.
  copyright 2005 David Heremans
}

proc vdrive {{diskdrive "diska"} {step 1}} {
	# Get current disk
	if {[catch {set cmd [$diskdrive]}]} {error "No such drive: $diskdrive"}

	# Skip for empty drive or 'special' disk
	set options [lindex $cmd 2]
	if       {"empty" in $options} {
		error "No disk in drive: $diskdrive"
	} elseif {"ramdsk" in $options} {
		error "Vdrive not possible on ramdsk"
	} elseif {"dirasdisk" in $options} {
		error "Vdrive not possible on DirAsDisk"
	}

	# Remove (dsk|di1|di2|xsa|dmk)(.gz)? extention
	set base [lindex $cmd 1]
	set ext ""
	set tmp [file extension $base]
	foreach i {".gz" ".zip"} {
		if {[string equal -nocase $i $tmp]} {
			set ext $tmp
			set base [file rootname $base]
			break
		}
	}
	set tmp [file extension $base]
	foreach i {".dsk" ".di1" ".di2" ".xsa" ".dmk"} {
		if {[string equal -nocase $i $tmp]} {
			set ext ${tmp}${ext}
			set base [file rootname $base]
			break
		}
	}

	# Split on trailing digits
	if {![regexp -indices {[0-9]+$} $base match]} {
		error "Name doesn't end in a number"
	}
	set i [lindex $match 0]
	set num  [string range $base $i end]
	set base [string range $base 0 $i-1]

	# Calculate range (number of digits)
	# Trim leading zeros (avoid interpreting the value as octal)
	set digits [string length $num]
	set range [expr {int(pow(10, $digits))}]
	set num [string trimleft $num 0]
	set fmt "%s%0${digits}d%s"

	# Increase (decrease) number until new file is found.
	set orig $num
	while 1 {
		set num [expr {($num + $step) % $range}]
		if {$num == $orig} {
			# We're back at the original. Explicitly test for this
			# because the original file might not exist anymore.
			return
		}
		# Construct new filename (including leading zeros)
		set newfile [format $fmt $base $num $ext]
		if {[file exists $newfile]} {
			# New file exists, insert in the disk drive
			diska $newfile
			return "New diskimage: $newfile"
		}
	}
}
