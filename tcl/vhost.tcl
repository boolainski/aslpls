set operid "xxx"
set operpass "xxxx"

set badwords { *<censored>* *service* *dalechat* *chatzona* *netadmin* *administrador* *administrator* *puntochat* *services* *digitalsands* *g0v* *admin* *fark* *fag* *!@#$* *suck* *shoot* *asshole* *zub* *bitch* *cock* *@#$* *whore* *slut* *fartknocker* *ass* *bastard* *black* *pussy* *dickhead* *nigga* *piss* *maricon* *shoot* *prick* *sucks* *dicks* *pricks* *.htm* *www.* *#* *channel* *sex* *ass* *trick* *fuk* *azz* *hail* *hitler* *gov* *mil* *cyberarmy* *cia* *fbi* *nsa* *dod* *undernet.org* *oper* }
 
bind evnt - init-server oper
bind pub -|- !ip vhost
bind join -|- * joinnotice

proc oper init-server { putserv "OPER $::operid $::operpass" }

proc joinnotice {nick host handle chan } {
    putserv "NOTICE $nick : Para cambiar tu ip utiliza el comando !ip <la ip que queiras>. Ejem: !ip Yo.me.encanta.el.chat"
  }

proc vhost {nick host hand chan vhostcheck} {
if {[string match "*.*.*" [string tolower $vhostcheck]]} {
  set temp 0
  set results 0
   #$temp<=X X = number of space delimited tokens in the badwords variable.
   while {$temp<=47} {
     foreach x [string tolower $::badwords] {
     if {[string match $x [string tolower $vhostcheck]]} {
     incr results
     }
    }
    incr temp
   }
   unset temp
   if { $results > 0 } {
   putserv "PRIVMSG $chan :$nick No se ha podido cambiar tu ip virtual, $vhostcheck la ip deseada es invalida/prohibida."
   } else {
   putserv "PRIVMSG $chan :$nick Tu ip virtual se ha cambiado a '$vhostcheck'"
   #putserv "PRIVMSG nickserv :vhost $nick ON $vhostcheck"
}
  } else {
  putserv "PRIVMSG $chan :$nick Tu ip virtual debe poseer al menos 2(dos) '.'s"
  }
}