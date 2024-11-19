package provide cheatfinder 0.5

set_help_text findcheat \
{Cheat finder version 0.5

Welcome to the openMSX cheat finder. Please visit
  http://forum.vampier.net/viewtopic.php?t=32 and
  http://www.youtube.com/watch?v=F11ltfkCtKo
for a quick tutorial

Usage:
  findcheat [-start] [-max n] [expression]
     -start     :  restart search, discard previously found addresses
     -max n     :  show max n results
     expression :  TODO

Examples:
  findcheat 42                 search for specific value
  findcheat bigger             search for increased values
  findcheat new == (2 * old)   search for doubled values
  findcheat new == (old - 1)   search for values decreased by 1
  findcheat                    repeat the results from the previous operation
  findcheat -start new < 10    restart and search for values less than 10
  findcheat -max 40 smaller    search for smaller values, show max 40 results
  findcheat -start addr>0xe000 && addr<0xefff search in defined memory locations
}

namespace eval cheat_finder {

variable max_num_results 15 ;# maximum to display cheats
variable mem

# build translation dictionary for convenience expressions
variable translate [dict create \
	""         "true"       \
	                        \
	"smaller"  "new < old"  \
	"less"     "new < old"  \
	"bigger"   "new > old"  \
	"more"     "new > old"  \
	"greater"  "new > old"  \
	                        \
	"le"       "new <= old" \
	"loe"      "new <= old" \
	"ge"       "new >= old" \
	"goe"      "new >= old" \
	"moe"      "new >= old" \
	                        \
	"equal"    "new == old" \
	"eq"       "new == old" \
	"notequal" "new != old" \
	"ne"       "new != old" \
	                        \
	"<="       "new <= old" \
	">="       "new >= old" \
	"<"        "new <  old" \
	">"        "new >  old" \
	"=="       "new == old" \
	"!="       "new != old"]

set_tabcompletion_proc findcheat [namespace code tab_cheat_type]

proc tab_cheat_type {args} {
	variable translate

	set result [dict keys $translate]
	lappend result "-start" "-max"
	return $result
}

# Restart cheat finder.
proc start {} {
	variable mem [dict create]

	set mymem [debug read_block memory 0 0x10000]
	binary scan $mymem c* values
	set addr 0
	foreach val $values {
		dict append mem $addr $val
		incr addr
	}
}

# Helper function to do the actual search.
# Returns a list of triplets (addr, old, new)
proc search {expression} {
	variable mem

	set result [list]
	dict for {addr old} $mem {
		set new [debug read memory $addr]
		#note: NO braces around $expression
		if $expression {
			dict set mem $addr $new
			lappend result [list $addr $old $new]
		} else {
			dict unset mem $addr
		}
	}
	return $result
}

# main routine
proc findcheat {args} {
	variable mem
	variable max_num_results
	variable translate

	# create mem dictionary
	if {![info exists mem]} start

	# parse options
	while (1) {
		switch -- [lindex $args 0] {
		"-max" {
			  set max_num_results [lindex $args 1]
			  set args [lrange $args 2 end]
		}
		"-start" {
			start
			set args [lrange $args 1 end]
		}
		"default" break
		}
	}

	# all remaining arguments form the expression
	set expression [join $args]

	if {[dict exists $translate $expression]} {
		# translate a convenience expression into a real expression
		set expression [dict get $translate $expression]
	} elseif {[string is integer $expression]} {
		# search for a specific value
		set expression "new == $expression"
	}

	# prefix 'old', 'new' and 'addr' with '$'
	set expression [string map {old $old new $new addr $addr} $expression]

	# search memory
	set result [search $expression]

	# display the result
	set num [llength $result]
	if {$num == 0} {
		return "No results left"
	} elseif {$num <= $max_num_results} {
		set output ""
		set sorted [lsort -integer -index 0 $result]
		foreach {addr old new} [join $sorted] {
			append output [format "0x%04X : %d -> %d\n" $addr $old $new]
		}
		return $output
	} else {
		return "$num results found -> Maximum result to display set to $max_num_results "
	}
}

namespace export findcheat

} ;# namespace cheat_finder

namespace import cheat_finder::*
