# rsh-Xlogin.tcl - by rehash
# Copyright (C) 2004, 2005 rehash.
# All rights reserverd.
#
#            _            _
#    _ _ ___| |_  __ _ __| |_
#   | '_/ -_) ' \/ _` (_-< ' \
#   |_| \___|_||_\__,_/__/_||_|
#   rehash@relevant-undernet.org
#
#  Contact: E-mail: rehash@relevant-undernet.org
#  Web: www.relevant-undernet.org
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
##############################################################################
# Some credit #
###############
set rsh(author) "rehash"
set rsh(version) "0.1"
set rsh(bold) "\002"

###########################
# Put here your username. #
###########################
set rsh(user) "username"

###########################
# Put here your password. #
###########################
set rsh(pass) "password"

###################################################
# Put here the modes you wish to set after login. #
# Mode "x" will enable the spoofed hostname like  #
# *!ident@username.user.undernet.org              #
###################################################
set rsh(mode) "x"

########################################################################
# Set here the time interval the bot will send the login message to X. #
# By default is set to 10 minutes.                                     #
########################################################################
set rsh(interval) "10"

#################
# The procedure #
#################
proc login {} {
	if {($::rsh(mode) != "") && ($::rsh(user) != "") && ($::rsh(pass) != "")} {
		dccbroadcast "Sending login message to X, and set mode $::rsh(bold)$::rsh(mode)$::rsh(bold)."
		putquick "PRIVMSG x@channels.undernet.org login $::rsh(user) $::rsh(pass)"
		putquick "MODE $::botnick +x"
	}
	if {($::rsh(mode) == "") && ($::rsh(user) != "") && ($::rsh(pass) != "")} {
		dccbroadcast "Sending login message to X, without setting any modes!"
		putquick "PRIVMSG x@channels.undernet.org login $::rsh(user) $::rsh(pass)"
	}
	if {($::rsh(mode) != "") && ($::rsh(user) == "") && ($::rsh(pass) != "")} {
		dccbroadcast "ERROR: no USERNAME specified, please edit the script!"
	}
	if {($::rsh(mode) != "") && ($::rsh(user) != "") && ($::rsh(pass) == "")} {
		dccbroadcast "ERROR: no PASSWORD specified, please edit the script!"
	}
	if {($::rsh(mode) != "") && ($::rsh(user) == "") && ($::rsh(pass) == "")} {
		dccbroadcast "ERROR: no USERNAME and PASSWORD specified, please edit the script!"
	}
	if {($::rsh(mode) == "") && ($::rsh(user) == "") && ($::rsh(pass) == "")} {
		dccbroadcast "ERROR: no MODE, USERNAME and PASSWORD specified, please edit the script!"
	}
}

##############
# The timer. #
##############
timer $::rsh(interval) login

putlog "$::rsh(bold)rsh-Xlogin.tcl$::rsh(bold) version $::rsh(bold)$::rsh(version)$::rsh(bold) by $::rsh(bold)$::rsh(author)$::rsh(bold) loaded."