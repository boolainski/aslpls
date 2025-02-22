#------------------------------------------------------------#
# Icecast script to announce musics from your online radio   #
# This should work out of the box with single source streams #
#------------------------------------------------------------#

#------------------------------------------------------------------------#
# Commands:                                                              #
# - !music - Displays the current music playing                          #
#                                                                        #
# - !icecast <on/off> - Enables/disables the ability to see the current  #
#   music playing with the !music command                                #
#                                                                        #
# - !iceauto <on/off> - Enables/disables the automatic annoucement of    #
#   the current music playing (check is done every minute, but the music #
#   is only announced if it has changed                                  #
#------------------------------------------------------------------------#
namespace eval icecast {

	#---------------#
	# Configuration #
	#---------------#
	# Trigger
	set trigger "!"

	# URL for the json page
	set jsonURL "https://pearl.radiomania.rocks:8000/status-json.xsl"

	# Radio Name
	set radioName "RadioMania"

	# Radio URL
	set listenURL "https://radiomania.rocks"

	# Binds
	bind cron - "* * * * *" ::icecast::autoplaying
	bind pub - ${::icecast::trigger}music ::icecast::nowplaying
	bind pub - ${::icecast::trigger}icecast ::icecast::on_off
	bind pub - ${::icecast::trigger}iceauto ::icecast::auto_onoff

	#----------------------#
	# End of configuration #
	#----------------------#
	### Requirements ###
	package require http
	package require json
	
	# Comment out the next line if you don't use HTTPS
	package require tls 1.7.11

	### Flags ###
	setudef flag icecast
	setudef flag iceauto

	### Last track ###
	if {![info exists ::icecast::lastTrack]} { set lastTrack "" }

	# Procs
	proc nowplaying {nick uhost hand chan text} {

		if {![channel get $chan icecast]} {
			putserv "PRIVMSG $chan :ERROR! Icecast not enabled on ${chan}."
			return 0
		}
		::icecast::announce $chan
	}

	proc autoplaying {min hour day month dow} {
		::icecast::announce all
	}

	proc announce {tchan} {

		# Comment out the next line if you don't use HTTPS
		::http::register https 443 [list ::tls::socket -autoservername true]

		set token [http::geturl "$::icecast::jsonURL" -timeout 10000]
		set data [http::data $token]
		set datadict [::json::json2dict $data]
		::http::cleanup $token

		if {![dict exists $datadict icestats source]} {
			if {$tchan ne "all" } {
				putserv "PRIVMSG $tchan :No source playing"
				return 0
			} else {
				return 0
			}
		}

		set dj [dict get $datadict icestats source server_name]
		set title [dict get $datadict icestats source title]
		
		if {$tchan ne "all"} {
			putserv "PRIVMSG $tchan :\[$::icecast::radioName\] DJ: ${dj} :: Song: $title :: Tune in: $::icecast::listenURL"
			return
		} else {
			if {$::icecast::lastTrack ne "$title"} {
				set ::icecast::lastTrack "$title"
				
				foreach chan [channels] {
					if {[channel get $chan iceauto]} {
						putserv "PRIVMSG $chan :\[$::icecast::radioName\] DJ: ${dj} :: Song:35 $title 1:: Tune in: $::icecast::listenURL"
					}
				}
			}
		}
	}

	proc on_off {nick uhost hand chan text} {

		set option [lindex [split $text] 0]

		if {![matchattr [nick2hand $nick] m]} {
			putserv "PRIMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		if {$option eq "on"} {
			if {[channel get $chan icecast]} {
				putserv "PRIVMSG $chan :ERROR! Icecast already enabled on $chan"
				return 0
			} else {
				channel set $chan +icecast
				putserv "PRIVMSG $chan :Icecast enabled on $chan"
				return 0
			}
		} elseif {$option eq "off"} {
			if {![channel get $chan icecast]} {
				putserv "PRIVMSG $chan :ERROR! Icecast already disabled on $chan"
				return 0
			} else {
				channel set $chan -icecast
				putserv "PRIVMSG $chan :Icecast disabled on $chan"
				return 0
			}
		} else {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}icecast on/off"
		}
	}

	proc auto_onoff {nick uhost hand chan text} {

		set option [lindex [split $text] 0]

		if {![matchattr [nick2hand $nick] m]} {
			putserv "PRIVMSG $chan :ERROR! You don't have access, ${nick}!"
			return 0
		}

		if {$option eq "on"} {
			if {[channel get $chan iceauto]} {
				putserv "PRIVMSG $chan :ERROR! Auto Icecast already enabled on $chan"
				return 0
			} else {
				channel set $chan +iceauto
				putserv "PRIVMSG $chan :Auto Icecast enabled on $chan"
				return 0
			}
		} elseif {$option eq "off"} {
			if {![channel get $chan iceauto]} {
				putserv "PRIVMSG $chan :ERROR! Auto Icecast already disabled on $chan"
				return 0
			} else {
				channel set $chan -iceauto
				putserv "PRIVMSG $chan :Auto Icecast disabled on $chan"
				return 0
			}
		} else {
			putserv "PRIVMSG $chan :ERROR! Syntax: ${::icecast::trigger}iceauto on/off"
			return 0
		}
	}
}; # end of icecast space