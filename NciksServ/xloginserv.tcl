## Description:  
## Simplified Auto Login X TCL script
## by aslpls

# Goger Identify TCL
putlog "Auto X-Login TCL loaded - aslpls"

### Setup
# Set nickname and password for login - edit as needed
set nickname "username"
set password "password"
set login "x@channels.undernet.org"  ;# Server address to use

### Helper function for common actions

proc send_command {command} {
    global nickname password login
    putquick "PRIVMSG $login :$command $nickname $password"
}

# Bind commands to functions
bind pub m .login  do_login


### Procedure Definitions

# Manual Login X
proc do_login {nick host handle chan text} {
    send_command "login"
    putserv "NOTICE $nick :Authenticating to $login..."
}

### Initial Setup
set init-server {  
    send_command "login"
    putserv "MODE $nick +x"
}
