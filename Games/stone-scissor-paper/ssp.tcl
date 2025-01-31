
###
### Stone Scissor Paper
###

## Initial version
namespace eval ssp {

	bind pub - !choose ::ssp::choose
	 
	variable elems {"stone" "scissor" "paper"}
	variable version "1.0"
	
	proc choose {nick uhost hand chan text} {
		set args [split $text]
		if {[string trim $text] eq "" || [llength $args] != 2} {
			putserv "PRIVMSG $chan :command is: !choose <paper | scissor | stone> <opponent>"
			return
		}
		if {[lsearch -nocase $::ssp::elems [join [lindex $args 0]]] == -1} {
			putserv "PRIVMSG $chan :choose paper, scissor or stone"
			return
		}
		set cmd [string tolower [join [lindex $args 0]]]
		set opp [join [lindex $args 1]]
		if {![onchan $opp $chan]} {
			putserv "PRIVMSG $chan :Cannot find $opp on $chan"
			return 0
		}
		
		set ssp [lindex $::ssp::elems [rand [llength $::ssp::elems]]]
		if {$cmd eq $ssp} {
			putserv "PRIVMSG $chan :You and $opp have \0037$cmd\003. It's a \00312-DRAW-\003" 
			return 0
		}
		switch $cmd {
			"stone" {
				if {$ssp eq "paper"} { set win "\0033WON\003" } else { set win "\0034LOSE\003" }
			}
			"paper" {
				if {$ssp eq "scissor"} { set win "\0033WON\003" } else { set win "\0034LOSE\003" }
			}
			"scissor" {
				if {$ssp eq "stone"} { set win "\0033WON\003" } else { set win "\0034LOSE\003" }
			}
		}
		putserv "PRIVMSG $chan :[format "You have \0037%1\$s\003 and %2\$s have \0037%3\$s\003: you %4\$s" $cmd $opp $ssp $win]"
	}
	
	putlog "ssp.tcl v${::ssp::version} loaded."
}
