namespace eval roulette {

   variable lang fr
   variable maxnoplay 3
   
   setudef flag roulette
   setudef flag colorized
   variable red {1 3 5 7 9 12 14 16 18 19 21 23 25 27 30 32 34 36}
   variable draw
   variable running
   variable nobet
   variable wallets
   variable db

   proc isOddEven {nb} {
      return [expr {$nb % 2 ? [::msgcat::mc "Odd"] : [::msgcat::mc "Even"]}]
   }
   
   proc isLowHigh {nb} {
      return [expr {$nb <= 18 ? [::msgcat::mc "Low"] : [::msgcat::mc "High"]}]
   }
   
   proc isRedBlack {nb} {
      set color [expr {$nb in [set [namespace current]::red] ? [::msgcat::mc "Red"] : [::msgcat::mc "Black"]}]
   }
   
   proc getDraw {} {
      set nb [expr {int(rand()*37)}]
      if {$nb == 0} {
         # treat 0 value...
         return "Got 0, green... special count"
      } else {
         return [msgcat::mc "%1\$s %2\$s %3\$s and %4\$s" $nb [[namespace current]::isRedBlack $nb] [[namespace current]::isOddEven $nb] [[namespace current]::isLowHigh $nb]]
      }
   }
   
   proc init {} {
      bind pub - "!roulette" [namespace current]::launchGame
      ::msgcat::mclocale en
      ::msgcat::mcset fr "!bet" "!mise"
      ::msgcat::mcset fr "Odd" "Pair"
      ::msgcat::mcset fr "Even" "Impair"
      ::msgcat::mcset fr "Low" "Manque"
      ::msgcat::mcset fr "High" "Passe"
      ::msgcat::mcset fr "Red" "Rouge"
      ::msgcat::mcset fr "Black" "Noir"
      ::msgcat::mcset fr "%1\$s %2\$s %3\$s and %4\$s" "%1\$s %2\$s %3\$s et %4\$s"
      ::msgcat::mcset fr "Place your bets, put your chips on the table" "Faites vos jeux"
      ::msgcat::mcset fr "Multiple bets are allowed for the same player" "Les parieurs peuvent poser plusieurs mises"
      ::msgcat::mcset fr "End of bets" "Les jeux sont faits"
      ::msgcat::mcset fr "Nothing goes on the table" "Rien ne va plus !"
      ::msgcat::mcset fr "!help" "!aide"
      ::msgcat::mclocale [set [namespace current]::lang]
      set [namespace current]::betable [list [::msgcat::mc "Odd"] [::msgcat::mc "Even"] [::msgcat::mc "Low"] [::msgcat::mc "High"] [::msgcat::mc "Red"] [::msgcat::mc "Black"]]
      for {set i 0} {$i<37} {incr i} { lappend [namespace current]::betable $i }
      putlog "Allowed bets: [set [namespace current]::betable]"
   }
   
   proc letBet {chan} {
      if {![info exists [namespace current]::db] || ![dict exists [set [namespace current]::db] $chan]} {
         set [namespace current]::db [dict create $chan players]
         #dict set [namespace current]::db $chan players {}
      }
      foreach p [dict keys [set [namespace current]::db] $chan players] {
         dict unset [namespace current]::db $chan players $p bets
      }
      if {[info exists [namespace current]::bets($chan)]} {
         unset [namespace current]::bets($chan)
      }
      putserv "PRIVMSG $chan :[::msgcat::mc "Place your bets, put your chips on the table"]"
      putserv "PRIVMSG $chan :[::msgcat::mc "Multiple bets are allowed for the same player"]"
      utimer 60 [list putserv "PRIVMSG $chan :[::msgcat::mc "End of bets"]"] 1 tmsg1
      utimer 90 [list putserv "PRIVMSG $chan :[::msgcat::mc "Nothing goes on the table"]"] 1 tmsg2
      incr [namespace current]::nobet($chan)
      bind pubm - "*[::msgcat::mc "!bet"]*" [namespace current]::doBet
      utimer 120 [list [namespace current]::endBet $chan] 1 tletbet
   }
   
   proc doBet {nick handle uhost chan text} {
      set text [string tolower [stripcodes * $text]]
      set cmd [lindex $text 0]
      set text [join [lrange $text 1 end]]
      if {$cmd ne "[::msgcat::mc "!bet"]"} {
         return
      }
      if {![dict exists [set [namespace current]::db] $chan players $nick wallet]} {
         dict set [namespace current]::db $chan players $nick wallet 100
      }
      set [namespace current]::nobet($chan) 0
      set bets [split $text ","]
      set tmp [list]
      set mu 0
      foreach b $bets {
         lassign [split [join $b] " "] money target
         if {![string is integer $money] || $money < 1} {
            putquick "PRIVMSG $chan :[::msgcat::mc "%1\$s is not a good value for bet, type %2\$s for help" $money [::msgcat::mc "!help"]]"
            continue
         }
         if {[lsearch -nocase [set [namespace current]::betable] $target]<0} {
            putquick "PRIVMSG $chan :[::msgcat::mc "%1\$s is not a good value for bet, type %2\$s for help" $target [::msgcat::mc "!help"]]"
            continue
         }
         incr mu $money
         lappend tmp [list $target $money]
      }
      #if {$mu > [set [namespace current]::wallets($chan,$nick)]} { #}
      if {$mu > [dict get [set [namespace current]::db] $chan players $nick wallet]} {
         putquick "PRIVMSG $chan :[::msgcat::mc "Sorry %1\$s but you can't bet %2\$s, you only have %3\$s in your wallet" $nick $mu [dict get [set [namespace current]::db] $chan players $nick wallet]]"
         return
      }
      foreach b $tmp {
         lassign $b t m
         dict incr [namespace current]::db $chan players $nick bets $t $m
         dict incr [namespace current]::db $chan players $nick wallet [expr {-1 * $mu}]
         putserv "PRIVMSG $chan :[::msgcat::mc "%1\$s, your wallet now contains %2\$s" $nick [dict get [set [namespace current]::db] $chan players $nick wallet]"
      }
   }
   
   proc endBet {chan} {
      unbind pubm - "*[::msgcat::mc "!bet"]*" [namespace current]::doBet
      putserv "PRIVMSG $chan :[[namespace current]::getDraw]"
      if {[info exists [namespace current]::nobet($chan)] && [set [namespace current]::nobet($chan)]>=[set [namespace current]::maxnoplay]} {
         putserv "PRIVMSG $chan :[::msgcat::mc "Noone seems to play, I stop. Type !roulette to launch a new game"]"
         [namespace current]::endGame $chan
         return
      }
      putlog "End of turn - [set [namespace current]::nobet($chan)] turns with no bet"
      utimer 30 [list [namespace current]::letBet $chan] 1 tendbet
   }
   
   proc endGame {chan} {
      foreach b [binds "[namespace current]*"] {
         lassign $b t f k n c
         unbind $t $f $k $c
      }
      set [namespace current]::running($chan) 0
      bind pub - "!roulette" [namespace current]::launchGame
   }
   
   proc launchGame {nick uhost handle chan text} {
      putlog "$nick starts game on $chan"
      if {![channel get $chan roulette]} {
         putquick "PRIVMSG $chan :[::msgcat::mc "Sorry %1\$s, Roulette is not active here" $nick]"
         return
      }
      if {[info exists [namespace current]::running($chan)] && [set [namespace current]::running($chan)]==1} {
         putquick "PRIVMSG $chan :[::msgcat::mc "Sorry %1\$s, Roulette is already running here" $nick]"
         return
      }
      putquick "PRIVMSG $chan :[::msgcat::mc "Game starts in 10 seconds"]"
      set [namespace current]::running($chan) 1
      set [namespace current]::nobet($chan) 0
      utimer 10 [list [namespace current]::letBet $chan] 1 tlaunch
   }
   
   if {[catch {package require msgcat}]} {
      namespace eval ::msgcat {
         proc mc {text {str ""} args} { return [format $text $str $args] }
      }
   }
   
   [namespace current]::init
}