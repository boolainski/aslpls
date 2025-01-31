# This is an example of expformat procedure
# Do not modify the declaration and the return
#
# This example returns the 20 more recent weeks
# in a <ul></ul> format

proc expformat {archives_scores} {
	set archives [lreverse [split $archives_scores "\n"]]
	set reverse_scores_archive {"<ul>"}
	set cpt 0
	foreach templine $archives {
		if { $cpt<20 && [regexp {(\d{2}\/\d{2}\/\d{4})-(\d{2}:\d{2}:\d{2}).+(\d{2}\/\d{2}\/\d{4})-(\d{2}:\d{2}:\d{2}) : (.+)} $templine a dates times datee timee players] } {
			regsub -all { \| } $players ", " players
			lappend reverse_scores_archive "<li>du $dates au $datee : $players</li>"
			incr cpt
		}
	}
	lappend reverse_scores_archive "</ul>"
	return [join $reverse_scores_archive "\n"]
}
