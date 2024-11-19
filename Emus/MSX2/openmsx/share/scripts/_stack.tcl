set_help_text stack \
{Show the <count> top most entries on the CPU stack.

If <count> is not specified, 8 entries are returned.
Usage:
   stack [<count>]
}
proc stack {{depth 8}} {
	set result ""
	for {set i 0; set sp [reg SP]} {$i < $depth} {incr i; incr sp 2} {
		append result [format "%04x: %04x\n" $sp [peek16 $sp]]
	}
	return $result
}
