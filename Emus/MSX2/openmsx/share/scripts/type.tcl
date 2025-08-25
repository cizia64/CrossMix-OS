namespace eval type {

user_setting create string default_type_proc \
{Determines which implementation is used for the generic type command:
type_via_keyboard or type_via_keybuf} type_via_keyboard

proc type {args} {
	$::default_type_proc {*}$args
}

proc type_help {args} {
	return \
"The type command is currently implemented by $::default_type_proc. (This can
be changed with the default_type_proc setting.) Here is the help of that
command:\n[help $::default_type_proc]"
}

set_help_proc type [namespace code type_help]

namespace export type
}

namespace import type::*

