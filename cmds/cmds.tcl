# |---------------------------------------------------------------------------------|
# |                ____ ____ ____ ____ ____ ____ ____ ____ ____                     |
# |               ||E |||g |||g |||t |||c |||l |||. |||u |||s ||                    |
# |               ||__|||__|||__|||__|||__|||__|||__|||__|||__||                    |
# |               |/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|                    | 
# |---------------------------------------------------------------------------------|
# |                                                                                 |
# | *** Website             @  https://www.Eggtcl.us                                |
# | *** GitHub              @  https://github.com/boolainski/aslpls		            |
# |                                                                                 |
# |---------------------------------------------------------------------------------|
# | *** IRC Support:                                                                |
# |                    #UnderX     @ iRc.UnderX.OrG                                 |
# |                                                                                 |
# | *** Contact:                                                                    |
# |                    Google Mail         : tabiligamer@gmail.com                  |
# |                                                                                 |
# |---------------------------------------------------------------------------------|
# |  INSTALLATION: 							            |
# |   ++ add "source scripts/cmds.tcl" to your eggdrop config and rehash the bot.   |
# |									            |
# |---------------------------------------------------------------------------------|
# |                               *** Commands ***                                  |
# |     +----------------+                                                          |
# |     [ ADMIN - PUBLIC ]                                                          |
# |     +----------------+                                                          |
# |      							                    |
# |		To Activate:						            |
# |     ++ .chanset #channel +cmds          	                                    |
# |		To De-activate:					                |
# |     ++ .chanset #channel -cmds                                                  |
# |                                                                                 |
# |---------------------------------------------------------------------------------|
# |                                                                                 |
# | IMPORTANT                                                                       |
# | - Basic IRC Script for FUN                                                      |
# | - To setup basic bot commands in your channel                                   |
# |                                                                                 |
# +---------------------------------------------------------------------------------|

#set this to "-" if you want everyone to use the !uptime command
set userflag "-"

#set this to any word you want to type if you want to see the bots uptime
set trig "!uptime"


#Main Commands

bind pub - !cmds pub_cmds
bind pub - !list pub_cmds

bind JOIN $userflag * onjoin_func
bind PUB $userflag $trig main_func


#----- Dont Edit If You Dont Know It ----#

setudef flag cmds
setudef flag list

proc main_func {nick uhost hand chan arg} {show_uptime $nick $uhost $hand $chan $arg}

proc show_uptime {nick uhost hand chan arg} {
catch {exec uptime} shelluptime
catch {exec uname -ms} shellver
puthelp "PRIVMSG $chan :\0038,2 Bot Uptime:\0037\002 [duration [expr [clock seconds] - $::uptime]] \002\003" 
puthelp "PRIVMSG $chan :\00311,2 Shell Uptime:\0039$shelluptime running on \0030$shellver \003"
}

proc pub_cmds {nick uhost hand channel arg} {
	putquick "NOTICE $nick :Public Commands: !time !portcheck 4IP PORT1 !nslookup 4IP1 !traceroute 4IP1 !check 4IP1 !ip 4\[nick|IP|host\]1"
}

proc onjoin_func {nick uhost hand chan} {
putserv "NOTICE $nick :Type \0032,0!list\003 to see available commands"
}

putlog "++ \[ - \00304PUBLIC\003 - \00306loaded\003 * \00303CMDS.TCL\003 * by aslpls \] ++"
