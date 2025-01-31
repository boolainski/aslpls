# pingmeter.tcl by arfer/nml375
# requires Tcl 8.4 or later
# requires channel to permit embelished text (colour) output
# requires utf-8 compliant IRC client
# each #channelname the script is to function in requires (in the partyline) .chanset #channelname +ping

# note that this script will probably not respond if any other client based script responds to the same command
# configure the command trigger accordingly

# assuming default trigger "." (period) syntax would be .ping ?target?
# replaces 10 green bars with 1 red bar per each 0.5 seconds (rounded) lag

##### CHANGELOG #############

# 1.0 07/03/09 beta
# 1.1 08/03/09 changed abs() math to modulus math to interpret integer wraparound

##### INSTALLATION ##########

# 1. configure pingmeter.tcl in a suitable text editor
# 2. upload configured pingmeter.tcl to bot's scripts subdirectory
# 3. add a line to bots .conf file 'source scripts/pingmeter.tcl'
# 4. restart the bot
# 5. requires '.chanset #channelname +ping' in the partyline to function in #channelname

##### CONFIGURATION #########

set vPingTrigger "!"

##### CODE ##################

proc pPingTrigger {} {
  global vPingTrigger
  return $vPingTrigger
}

set vPingVersion 1.1

setudef flag ping

bind CTCR - PING pPingCtcrReceive
bind PUB - [pPingTrigger]ping pPingPubCommand
bind RAW - 401 pPingRawOffline

proc pPingTimeout {} {
  global vPingOperation
  set schan [lindex $vPingOperation 0]
  set snick [lindex $vPingOperation 1]
  set tnick [lindex $vPingOperation 2]
  putserv "PRIVMSG $schan :\00304Error\003 (\00314$snick\003) operation timed out attempting to ping \00307$tnick\003"
  unset vPingOperation
  return 0
}

proc pPingCtcrReceive {nick uhost hand dest keyword txt} {
  global vPingOperation
  if {[info exists vPingOperation]} {
    set schan [lindex $vPingOperation 0]
    set snick [lindex $vPingOperation 1]
    set tnick [lindex $vPingOperation 2]
    set time1 [lindex $vPingOperation 3]
    if {([string equal -nocase $nick $tnick]) && ([regexp -- {^[0-9]+$} $txt])} {
      set time2 [expr {[clock clicks -milliseconds] % 16777216}]
      set elapsed [expr {(($time2 - $time1) % 16777216) / 1000.0}]
      set char [encoding convertto utf-8 \u258C]
      if {[expr {round($elapsed / 0.5)}] > 10} {set red 10} else {set red [expr {round($elapsed / 0.5)}]}
      set green [expr {10 - $red}]
      set output \00303[string repeat $char $green]\003\00304[string repeat $char $red]\003
      putserv "PRIVMSG $schan :\00310Compliance\003 (\00314$snick\003) $output $elapsed seconds from \00307$tnick\003"
      unset vPingOperation
      pPingKillutimer
    }
  }
  return 0
}

proc pPingKillutimer {} {
  foreach item [utimers] {
    if {[string equal pPingTimeout [lindex $item 1]]} {
      killutimer [lindex $item 2]
    }
  }
  return 0
}

proc pPingPubCommand {nick uhost hand channel txt} {
  global vPingOperation
  if {[channel get $channel ping]} {
    switch -- [llength [split [string trim $txt]]] {
      0 {set tnick $nick}
      1 {set tnick [string trim $txt]}
      default {
        putserv "PRIVMSG $channel :\00304Error\003 (\00314$nick\003) correct syntax is \00307!ping ?target?\003"
        return 0
      }
    }
    if {![info exists vPingOperation]} {
      if {[regexp -- {^[\x41-\x7D][-\d\x41-\x7D]*$} $tnick]} {
        set time1 [expr {[clock clicks -milliseconds] % 16777216}]
        putquick "PRIVMSG $tnick :\001PING [unixtime]\001"
        utimer 20 pPingTimeout
        set vPingOperation [list $channel $nick $tnick $time1]
      } else {putserv "PRIVMSG $channel :\00304Error\003 (\00314$nick\003) \00307$tnick\003 is not a valid nick"}
    } else {putserv "PRIVMSG $channel :\00304Error\003 (\00314$nick\003) a ping operation is still pending, please wait"}
  }
  return 0
}

proc pPingRawOffline {from keyword txt} {
  global vPingOperation
  if {[info exists vPingOperation]} {
    set schan [lindex $vPingOperation 0]
    set snick [lindex $vPingOperation 1]
    set tnick [lindex $vPingOperation 2]
    if {[string equal -nocase $tnick [lindex [split $txt] 1]]} {
      putserv "PRIVMSG $schan :\00304Error\003 (\00314$snick\003) \00307$tnick\003 is not online"
      unset vPingOperation
      pPingKillutimer
    }
  }
  return 0
}

putlog "pingmeter.tcl by arfer/nml375 version $vPingVersion loaded"
