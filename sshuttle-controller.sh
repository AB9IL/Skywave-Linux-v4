#!/bin/bash

# Copyright (c) 2021 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8
# config file format: one line per user account on the server
# each line contains: ip username port
# separate fields with a space
CONFIGFILE=$HOME/.ssh/config

ROFI_COMMAND1='rofi -dmenu -p Select -lines 3'
FZF_COMMAND1='fzf --layout=reverse --header=Select:'
ROFI_COMMAND2='rofi -dmenu -p Select'
FZF_COMMAND2='fzf --layout=reverse --header=Select:'
FZF_COMMAND3="vim $CONFIGFILE"
ROFI_COMMAND3="x-terminal-emulator -e vim $CONFIGFILE"

edit_data(){
    $COMMAND3
}

showhelp(){
echo -e "\nSSH Tunnel manager (using sshuttle).

Note:  You MUST set up key based logins on the servers.

Usage: $0 <option>
Options:    gui     Graphical user interface.
            --help  This help screen.\n"
}

start_sshuttle(){
    CHOICE="$(grep -E '^Host \w' $CONFIGFILE | awk '{print $2}' | $COMMAND2 )"
    [[ -z "$CHOICE" ]] && echo "No selection..." && exit 1
    sudo iptables-save > /tmp/iptables.backup; \
    x-terminal-emulator -e  sh -c "sshuttle \
        --verbose \
        --remote $CHOICE 0/0 \
        --ssh-cmd 'ssh' \
        --dns \
        --pidfile=/tmp/sshuttle.pid; \
        read line; kill $(cat /tmp/sshuttle.pid); \
        sudo iptables-restore < /tmp/iptables.backup " &
}

stop_sshuttle(){
kill $(cat /tmp/sshuttle.pid)
sudo iptables-restore < /tmp/iptables.backup
exit 0
}

case "$1" in
    "")
        COMMAND1=$FZF_COMMAND1
        COMMAND2=$FZF_COMMAND2
        COMMAND3=$FZF_COMMAND3
        ;;
    "gui")
        COMMAND1=$ROFI_COMMAND1
        COMMAND2=$ROFI_COMMAND2
        COMMAND3=$ROFI_COMMAND3
        ;;
    *)
        showhelp
        ;;
esac

OPTIONS="Start SSH tunneling
Edit your server data
Stop SSH tunneling"

# Take the choice; exit if no answer matches options.
REPLY="$(echo -e "$OPTIONS" | $COMMAND1 )"

[[  "$REPLY" == "Start SSH tunneling" ]] && start_sshuttle
[[  "$REPLY" == "Edit your server data" ]] && edit_data
[[  "$REPLY" == "Stop SSH tunneling" ]] && stop_sshuttle
