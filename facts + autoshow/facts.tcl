

############# Random FunFacts ##################
# A simple script to post random funfacts in a #
# channel.                                     #
#                                              #
# The bot randomly fetch funfacts from address #
# http://www.randomfunfacts.com/ and post it   #
# to the alocated channel in ever x minutes.   #
#                                              #
#                                              #
# Installation:                                #
# pop the script in your script folder and add #
# source scripts/fact.tcl to your eggdrop conf #
# file rehash / restart the bot.               #
#   ** THIS SCRIPT IS A MODIFIED SCRIPT        #
#                - Error                       #
#         irc.oddprotocol.org                  #
#             #oddprotocol                     #
################################################
                          


 package require http


################################################
#                Configuration                 #
#                                              #
#      Alocate a channel for the bot           #
################################################

set channel "#bottest"


#################################################
# Random facts timer. change it according to    #
# your needs.                                   #
#################################################

set time 1

#################################################
# Please dont touch anything bellow unless you  #
# know what you are doing.                      #
#################################################


if {[string compare [string index $time 0] "!"] == 0} { set timer [string range $time 1 end] } { set timer [expr $time * 60] } 
if {[lsearch -glob [utimers] "* fact *"] == -1} { utimer $timer fact }


proc fact {} { 
global channel time fact timer 
set url "http://www.randomfunfacts.com/"
set page [http::data [http::geturl $url]]
regexp {<i>(.*?)<\/i>} $page a fact 
#foreach line $fact { putserv "PRIVMSG $channel :Facts: $fact" } 
putserv "PRIVMSG $channel :Facts: $fact" 
if {[lsearch -glob [utimers] "* fact *"] == -1} { utimer $timer fact } 
}


putlog "funfact.tcl 1.0 (Random Fun Facts ) by Error Loaded."
