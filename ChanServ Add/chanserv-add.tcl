# +-------------------------------------------------------------------------------------+
# |                                                                                     |
# |                   Chanserv Add Access (Aop, SOP) v1.0.0                             |
# |                                                                                     |
# +-------------------------------------------------------------------------------------+
# |                                                                                     |
# | *** Website             @  https://www.RadioMania.Rocks                             |
# | *** GitHub              @  https://github.com/radiomania/aslpls                     |
# |                                                                                     |
# +-------------------------------------------------------------------------------------+
# | *** IRC Support:                                                                    |
# |                    #aslpls     @ DALnet                                             |
# |                    #aslpls     @ UnderNET                                           |
# |                    #aslpls     @ UnderX                                             |
# |                                                                                     |
# | *** Contact:                                                                        |
# |                    Google Mail         : tabiligamer@gmail.com                      |
# |                                                                                     |
# |                                                                                     |
# |                                                                                     |
# |                                                                                     |
# +-------------------------------------------------------------------------------------+


# Define the channel and ChanServ nickname
set channel "#aslpls"
set chanserv "ChanServ@services.dal.net"

# Bind public commands for AOP and SOP management
bind pub - "!addaop" add_aop
bind pub - "!delaop" del_aop
bind pub - "!addsop" add_sop
bind pub - "!delsop" del_sop

# Procedure to add a user to the AOP list
proc add_aop {nick uhost hand chan text} {
    global channel chanserv

    if {$chan != $channel} {
        return
    }

    set params [split $text]
    if {[llength $params] < 1} {
        putserv "PRIVMSG $chan :Usage: !addaop <nickname>"
        return
    }

    set user [lindex $params 0]
    putserv "PRIVMSG $chanserv :AOP $channel ADD $user"
    putserv "PRIVMSG $chan :Added $user to the AutoOp (AOP) list."
}

# Procedure to delete a user from the AOP list
proc del_aop {nick uhost hand chan text} {
    global channel chanserv

    if {$chan != $channel} {
        return
    }

    set params [split $text]
    if {[llength $params] < 1} {
        putserv "PRIVMSG $chan :Usage: !delaop <nickname>"
        return
    }

    set user [lindex $params 0]
    putserv "PRIVMSG $chanserv :AOP $channel DEL $user"
    putserv "PRIVMSG $chan :Removed $user from the AutoOp (AOP) list."
}

# Procedure to add a user to the SOP list
proc add_sop {nick uhost hand chan text} {
    global channel chanserv

    if {$chan != $channel} {
        return
    }

    set params [split $text]
    if {[llength $params] < 1} {
        putserv "PRIVMSG $chan :Usage: !addsop <nickname>"
        return
    }

    set user [lindex $params 0]
    putserv "PRIVMSG $chanserv :SOP $channel ADD $user"
    putserv "PRIVMSG $chan :Added $user to the SuperOp (SOP) list."
}

# Procedure to delete a user from the SOP list
proc del_sop {nick uhost hand chan text} {
    global channel chanserv

    if {$chan != $channel} {
        return
    }

    set params [split $text]
    if {[llength $params] < 1} {
        putserv "PRIVMSG $chan :Usage: !delsop <nickname>"
        return
    }

    set user [lindex $params 0]
    putserv "PRIVMSG $chanserv :SOP $channel DEL $user"
    putserv "PRIVMSG $chan :Removed $user from the SuperOp (SOP) list."
}



putlog "Chanserv Add/Delete AOP-SOP Access Script Made By aslpls"
