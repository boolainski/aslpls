# List all ascii arts files and bind them
set artdir "scripts/arts/"

foreach aafile [glob -directory $artdir -types {f} -- ascii.*.txt] {
	scan $aafile {scripts/arts/ascii.%[^.].txt} name
	bind pubm - "* !${name}" drawme
}

proc drawme {nick uhost handle chan text} {
	set text [join [lindex [split [stripcodes abcgru $text]] 0]]
	if {[string first ! $text]!=0} {
		putlog "error 1"
		return
	}
	set fname [string tolower [string range $text 1 end]]
	if {![file exists "${::artdir}ascii.${fname}.txt"]} {
		putlog "error ${::artdir}ascii.${fname}.txt"
		return
	}
	set fi [open ${::artdir}ascii.${fname}.txt r]
	set draw [read -nonewline $fi]
	close $fi
	foreach line [split $draw "\n"] {
		putnow "PRIVMSG $chan :$line"
	}
}

putlog "Ascii drawer 1.0 by CrazyCat <https://www.eggdrop.fr> loaded"