# Provide 'quit' command for backwards compatibility. The preferred command is
# now 'exit'. Tcl normally only has a 'exit' command. Also most shells have
# exit but no quit.
proc quit {} {
	# wouter: I prefer to not deprecate this, because I occasionally still
	# use this myself.
	exit
}

proc decr {var {num 1}} {
	puts stderr "This command ('decr $var $num') has been deprecated (and may be removed in a future release), please use 'incr $var -$num' instead!"
	uplevel incr $var [expr {-$num}]
}
proc restoredefault {var} {
	puts stderr "This command ('restoredefault $var') has been deprecated (and may be removed in a future release), please use 'unset $var' instead!"
	uplevel unset $var
}
proc alias {cmd body} {
	puts stderr "This command ('alias $cmd $body') has been deprecated (and may be removed in a future release), please define a proc instead: proc $cmd {} $body"
	proc $cmd {} $body
}
