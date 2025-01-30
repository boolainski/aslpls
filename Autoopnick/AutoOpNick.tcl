#Autoop Nick TCL By CoMMy v1.0 TESTED!!!
#You Can Find Me: CoMMy@Undernet
#Please Contact Me At kirian100@yahoo.com 
#If you find any bugs Or Any Updates You Want Please Contact Me. :)
#Enjoy!


#####################################
###-HISTORY-#########################
###
###v1.0 - Made the script, of course there are bugs!!!
###
###v1.1 - Fixed +autooopnick flag to +autoopnick, (Big Thanks goes to Jason Power for reporting it)
###	  Fixed ischanset proc, was unnecesary now. Script is Faster Now.
###	  Added !help command. Shows a list of commands.
###
######################################
######################################


#Configuration Starts Here.

#Set Here The Public Character You Want.
set char "!"

#NOTE: YOU HAVE TO SET THE CHANNEL TO +autoopnick FOR THE BOT TO ACT.

#Configuration Ends Here.

#Please Dont Change Anthing If You Don't Know TCL :)
#---------------------------------------------------

setudef flag autoopnick
bind pub n ${::char}help help_auto_op
bind pub n ${::char}addnick add_auto_op
bind pub n ${::char}listnick list_auto_op
bind pub n ${::char}delnick del_auto_op
bind pub n ${::char}dellist dellist_auto_op
bind join - * join_check

proc help_auto_op {nick host handle chan args} {
global botnick char
putnotc $nick "Starting List Of Available Commands."
putnotc $nick "${char}help - Shows This List."
putnotc $nick "${char}addnick <nick> - Adds a Nickname to the list."
putnotc $nick "${char}delnick <nick> - Deletes a Nickname from the list."
putnotc $nick "${char}listnick - Lists the Nickname(s) currently in the list."
putnotc $nick "${char}dellist - Deletes The entire list. CAREFULL!!!"
return 1 }

proc dellist_auto_op {nick host handle chan args} {
global botnick
putnotc $nick "Start Of Delete Of The Entire List"
dellist $nick
return 1 }

proc add_auto_op {nick host handle chan args} {
global botnick
set who [lindex $args 0]
if {$who == ""} {
putnotc $nick "Please Specify A Nickname To Add"
return 0 }
addperson $nick $who
return 1 }

proc del_auto_op {nick host handle chan args} {
global botnick
set who [lindex $args 0]
if {$who == ""} {
putnotc $nick "Please Specify A Nickname To Delete."
return 0 }
delperson $nick $who
return 1 }

proc list_auto_op {nick host handle chan args} {
global botnick
listnicks $nick
return 1 }

proc join_check {nick host handle chan} {
global botnick
if {![channel get $chan autoopnick]} {return 0}
set fp [open scripts/autooplist.txt r]
set lines [split [read $fp] \n]
set idx [lsearch -glob $lines "$nick"]
if {$idx != -1} {
  putquick "MODE $chan +o $nick"
  close $fp
} else {
  close $fp
  return 0 }
return 1 }

proc addperson { nick person } {
global config
set fp [open scripts/autooplist.txt r]
set lines [split [read $fp] \n]
close $fp
set idx [lsearch -glob $lines "$person"]
set newline [list $person]
if {$idx != -1} { 
  putnotc $nick "ERROR: Nickname Already Exists"
  return 0
} else {
  lappend lines $newline
}
set fp [open scripts/autooplist.txt w]
puts $fp [join $lines \n]
putnotc $nick "Successfully Added $person To List"
close $fp
rehash }

proc delperson { nick person } {
global config
set fp [open scripts/autooplist.txt r]
set lines [split [read $fp] \n]
close $fp
set idx [lsearch -glob $lines "$person"]
set newline [list  ]
if {$idx != -1} {
  set lines [lreplace $lines $idx $idx $newline]
} else {
  putnotc $nick "ERROR: Nickname Doesn't Exist"
  return 0
}
set fp [open scripts/autooplist.txt w]
puts -nonewline $fp [join $lines \n]
putnotc $nick "Successfully Deleted $person From List"
close $fp
rehash }

proc dellist { nick } {
global config
set fp [open scripts/autooplist.txt r]
set lines [split [read $fp] \n]
close $fp
set newline [list  ]
set fp [open scripts/autooplist.txt w]
foreach line $lines {
puts -nonewline $fp [join $newline \n] }
putnotc $nick "Successfully Purged The List."
close $fp
rehash }

proc listnicks { nick } {
global config
set fp [open scripts/autooplist.txt r]
set lines [split [read $fp] \n]
close $fp
putnotc $nick "Playing AutoOp NickList:"
putnotc $nick "(NOTE:If Nothing Is Displayed Then The List Is Empty.)"
foreach line $lines {
putnotc $nick "$line" }
return 1 }
#---------------------------------------------------

putlog "AutoOp Nick TCL v1.1 By CoMMy LOADED..."