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
CONFIGFILE=$HOME/.config/sshuttle/sshuttle.conf

ROFI_COMMAND1='rofi -dmenu -p Select -lines 3'
FZF_COMMAND1='fzf --layout=reverse --header=Select:'
ROFI_COMMAND2='rofi -dmenu -p Select'
FZF_COMMAND2='fzf --layout=reverse --header=Select:'

edit_data(){
    vim $CONFIGFILE
}

showhelp(){
echo -e "\nSSH Tunnel manager (using sshuttle).

Note:  You MUST set up key based logins on the servers.

Usage: $0 <option>
Options:    gui     Graphical user interface.
            --help  This help screen.\n"
}

start_sshuttle(){
    readarray SERVERS < $CONFIGFILE
    CHOICE="$(echo "${SERVERS[@]}" | awk '{print $1, $2}' | $COMMAND2 )"
    [[ -z "$CHOICE" ]] && echo "No selection..." && exit 1
    # go back and find the correct entry; read the data and connect
    i=0
    while [ $i -lt ${#SERVERS[@]} ]; do
        # remove newlines and whitespace before looking for a match
        CHOICE="$(echo $CHOICE | tr -d ' ')"
        ITEM="$(echo "${SERVERS[i]}" | awk '{print $1, $2}' | tr -d \\n | tr -d ' ')"
        # set variables if there is a match
        if [ "$ITEM" == "$CHOICE" ]; then
                export SSHUTTLE_IP="$(echo "${SERVERS[i]}" | awk '{print $1}')"
                export SSHUTTLE_USER="$(echo "${SERVERS[i]}" | awk '{print $2}')"
                export SSHUTTLE_PORT="$(echo "${SERVERS[i]}" | awk '{print $3}')"
                sudo iptables-save > /tmp/iptables.backup; \
                x-terminal-emulator -e  sh -c "sshuttle -r $SSHUTTLE_USER@$SSHUTTLE_IP:$SSHUTTLE_PORT 0.0.0.0/0 \
                    --ssh-cmd 'ssh -o ServerAliveInterval=60' -v --dns \
                    -v --dns --pidfile=/tmp/sshuttle.pid; read line" &
                break
        fi
    ((i++))
    done
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
        ;;
    "gui")
        COMMAND1=$ROFI_COMMAND1
        COMMAND2=$ROFI_COMMAND2
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
