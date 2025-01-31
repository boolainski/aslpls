# Bartender v0.2b
# By CrazyCat <https://www.eggdrop.fr>
#
# type .chanset #channel +bar to activate on #channel
# help command is !bar (public command on channel)

namespace eval bartender {

   # List of replies
   variable replies
   # Variables:
   # - %nick : nick of the user
   # - %utoday, %utotal : user count for today and total
   # - %ctoday, %ctotal : channel count for today and total
   set replies(coke) {
      "Are you stupid? We doesn't do shit like this... GO SLAP YOUR SELF IN THE NUTS! :P"
   }
   set replies(coffee) {
      "Making a cup of coffee for %nick, %utoday made today of %utotal ordered wich make it the %ctotal time i make coffee"
   }
   set replies(bang) {
      "fills a bang from stash and serves it to %nick (%utoday/%utotal/%ctotal)"
   }
   set replies(cola) {
      "Serves icecold cola (%utoday/%utotal/%ctotal)" \
      "Serves cola that been laying in pile of shit ~45c (%utoday/%utotal/%ctotal)" \
      "Serves cola been standing close to box of dryice ~1,3c (%utoday/%utotal/%ctotal)" \
      "Serves cola that been standing next to comp for few hrs (%utoday/%utotal/%ctotal)"
   }
   set replies(beer) {
      "Serves icecold beer (%utoday/%utotal/%ctotal)"
   }
   set replies(joint) {
      "Grabs a joint to %nick from the stash (%utoday/%utotal/%ctotal)"
   }
   set replies(head) {
      ".h.e.a.d. (%utotal)" \
      "head for you sir. (%utotal)"
   }
   set replies(wine) {
      "pours up some fine stuff from the basement (%utotal)" \
      "here you are, found something out back (%utotal)" \
      "lucky you we just got one of this left enjoy (%utotal)" \
      "so youre hit hard, where you want it ?, dont cry"
   }
   set replies(mix) {
      "grinding up some weed for a mix (%utotal)" \
      "grabs some the good stuff for a mix (%utotal)" \
      "sneaks into g2x3ks stash and steals for a mix, here you go (%utotal)" \
      "goes strain hunting in india for some good shit for your mix (%utotal)" \
      "goes strain hunting in morocco for some good shit for your mix (%utotal)"
   }
   set replies(pipe) {
      "goes strain hunting in morocco for some good shit for your pipe (%utotal)" \
      "saw some shit in corner, fills a pipe (%utotal)" \
      "skunky just arrieved peace all over (%utotal)"
   }
   set replies(whiskey) {
      "serves whiskey on the rocks (%utotal)" \
      "found some weird looking bottle in corner, might hit gold cheers (%utotal)" \
      "cola and bad whiskey for you (%utotal)"
   }
   set replies(pussy) {
      "slaps %nick in face with a smelly pussy (%utotal)" \
      "Sends some pussy %nick`s way .. (%utotal)" \
      "not enough money to suply you aswell ... (%utotal)"
   }
   set replies(icecream) {
      "here %nick... one ball for you only (%utoday/%utotal/%ctotal)" \
      "finds a biig icecream for %nick eat and you get for free (50$ to use toilet) (%utoday/%utotal/%ctotal)" \
      "dusts off something that look like icecream from the corner of fridge, here %nick (%utoday/%utotal/%ctotal)"
   }
   
   set spam {
      "Hey hey there dont you think its going a bit to fast there only %since since youre last ..." \
      "I'm busy ..." \
      "havent you just had ?"
   }
   
   # antiflood delay (in seconds)
   variable delay 10
   
   ###############################
   ## DO NOT EDIT BELOW
   ###############################
   variable wait
   variable cmds {}
   
   variable author "CrazyCat"
   variable version "0.2b"
   setudef flag bar
   setudef str bardb
   
   # Running command
   proc process {nick uhost handle chan text} {
      if {![channel get $chan bar]} { return }
      set cmd [string range $::lastbind 1 end]
      if {![info exists ::bartender::wait($chan)] || $::bartender::wait($chan)<[clock seconds]} {
         set ::bartender::wait($chan) [expr [clock seconds]+3]
      } else {
         set since [expr $::bartender::wait($chan) - [clock seconds]]
         set answer [lindex $::bartender::spam [rand [llength $::bartender::spam]]]
         regsub -all -- %since $answer $since answer
         putquick "PRIVMSG $chan :$answer"
         return
      }
      if {![info exists ::bartender::replies($cmd)]} {
         ::bartender::help $nick $uhost $handle $chan $text
         return
      }
      set vict $nick
      set nick [string tolower $nick]
      if {$text ne "" && [onchan [join [lindex [split $text] 0]] $chan]} {
         set vict [join [lindex [split $text] 0]]
      }
      ::bartender::statadd $chan $nick $cmd
      set answer [lindex $::bartender::replies($cmd) [rand [llength $::bartender::replies($cmd)]]]
      putserv "PRIVMSG $chan :[::bartender::formatmsg $answer $cmd $chan $nick $vict]"
   }
   
   # Simple replacement of variables with values
   proc formatmsg {msg cmd chan nick vict} {
      set bar [channel get $chan bardb]
      set ctoday [dict get $bar today]
      set ctotal [dict get $bar total]
      set utoday [dict get $bar nicks $nick today]
      set utotal [dict get $bar nicks $nick total]
      set msg [string map [list %nick $vict %chan $chan %ctoday $ctoday %ctotal $ctotal %utotal $utotal %utoday $utoday] $msg]
      return $msg
   }
   
   # Add stats in bardb 
   proc statadd {chan nick cmd} {
      if {[channel get $chan bardb] eq ""} {
         dict set bar total 1
         dict set bar today 1
         dict set bar nicks $nick today 1
         dict set bar nicks $nick total 1
         channel set $chan bardb $bar
         return
      }
      set bar [channel get $chan bardb]
      dict incr bar total
      dict incr bar today
      if {![dict exists $bar nicks $nick]} {
         dict set bar nicks $nick today 1
         dict set bar nicks $nick total 1
      } else {
         set bn [dict get $bar nicks $nick]
         dict incr bn total
         dict incr bn today
         dict set bar nicks $nick $bn
      }
      channel set $chan bardb $bar
      return
   }
   
   # removes previous binds
   # Thanks to caesar
   foreach ele [binds [namespace current]::*] {
      if {[scan $ele {%s%s%s%d%s} type flags cmd hits func] != 5} continue
      if {$type ne "pub"} continue
      unbind $type $flags $cmd $func
   }

   # Creates associated binds
   foreach trigger [array names ::bartender::replies] {
      bind pub - !$trigger ::bartender::process
      lappend ::bartender::cmds "!$trigger"
   }
   
   # Small help: list all commands
   bind pub - !bar ::bartender::help
   proc help {nick uhost handle chan text} {
      if {![channel get $chan bar]} { return }
      putserv "PRIVMSG $chan :The bar have [join $::bartender::cmds]"
      return
   }
   
   # Reset "Today" stats
   bind time - "00 00 * *" ::bartender::restoday
   proc restoday {mi ho dm mo ye} {
      foreach chan [channels] {
         set bar [channel get $chan bardb]
         if {$bar ne ""} {
            dict set bar today 0
            foreach nick [dict keys [dict get $bar nicks]] {
               dict set bar nicks $nick today 0
            }
         }
         channel set $chan bardb $bar
      }
   }
   
   putlog "Bartender v${::bartender::version} by ${::bartender::author} loaded"
}
