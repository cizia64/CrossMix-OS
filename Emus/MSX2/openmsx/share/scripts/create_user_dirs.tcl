# pre-create directories in the openMSX user dir, for ease of use

set subdirs [list "systemroms" "software" "scripts" "skins" "machines" "extensions"]

foreach subdir $subdirs {
	set directory [file normalize $::env(OPENMSX_USER_DATA)/$subdir]
	if {![file exists $directory]} {
		set sourcedir [file normalize $::env(OPENMSX_SYSTEM_DATA)/$subdir]
		file mkdir $directory
		if {[file exists $sourcedir/README]} {
			file copy -- $sourcedir/README $directory
		}
	}
}
