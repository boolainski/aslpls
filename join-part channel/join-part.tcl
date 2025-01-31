
#####DONT EDIT IF YOU DONT UNDERSTAND ANY OF THE STUFF BELOW######

bind PUB $userflag !join join_func
bind PUB $userflag !part part_func


proc join_func {nick uhost hand chan arg} {
set target "[lindex $arg 0]"
if {[expr { $target == "" || [expr { [string index $target 0] != "#"}] } ]} { puthelp "NOTICE $nick :Command usage: !join <#channel>. Type !cmds for a list of commands."
		         return 1	
	} else { global server
		   channel add $target
               putserv "NOTICE $nick :Joined $target on $server"
             }
}

proc part_func {nick uhost hand chan arg} {
set ptarg "[lindex $arg 0]"
if {[expr { $ptarg == "" || [expr { [string index $ptarg 0] != "#"}] } ]} { puthelp "NOTICE $nick :Command usage: !part <#channel>. Type !cmds for a list of commands."
		         return 1	
	} else { global server
		   channel remove $ptarg
               putserv "NOTICE $nick :Parted $ptarg on $server"
             }
}



############################################################
