namespace eval quitmenu {

	proc quit_menu {} {
		set items [list "No" "Yes"]
		set menu_def \
			{ execute quitmenu::quit_menu_exec
				font-size 12
				border-size 2
				width 154
				xpos 80
				ypos 100
				header { text "Really exit openMSX?"
						font-size 14
						post-spacing 6 }}

		osd_menu::do_menu_open [osd_menu::prepare_menu_list $items [llength $items] $menu_def]
		activate_input_layer quit_menu
	}

	proc quit_menu_exec {item} {
		osd_menu::menu_close_all
		if {$item eq "Yes"} {exit}
	}
}
