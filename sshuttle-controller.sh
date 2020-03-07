#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8
configfile=$HOME/.config/sshuttle/sshuttle.conf
port='22'

save_data(){
OUTPUT=$(zenity --forms --title="Sshuttle SSH Tunneling Application" \
--text="Enter the remote server information.
Stand by to enter the server password after contact is made.
CTRL-C to exit the tunnel and restore network settings." \
--separator="," \
--add-entry="Remote server address" \
--add-entry="Remote server username" \
--add-entry="SSH port (default = 22)");

if [[ "$?" -ne "0" || -z "$?" ]]; then
    exit
fi

server=$(awk -F, '{print $1}' <<<$OUTPUT)
user=$(awk -F, '{print $2}' <<<$OUTPUT)
port=$(awk -F, '{print $3}' <<<$OUTPUT)

echo "server=$server
user=$user
port=$port" > $configfile
}


start_sshuttle(){
# get the server address, username, and ssh port
. $configfile

export server
export user
export port

sudo iptables-save > /tmp/iptables.backup
mate-terminal -e  'sh -c "sshuttle -r $user@$server:$port 0.0.0.0/0 -v --dns --pidfile=/tmp/sshuttle.pid; read line"' &
stop_sshuttle
}

stop_sshuttle(){
kill $(cat /tmp/sshuttle.pid)
sudo iptables-restore < /tmp/iptables.backup
}

ans=$(zenity  --list  --title "Sshuttle SSH Tunneling Application" --width=300 --height=180 \
--text "Save server data or start ssh tunneling.
** You must set up your own password or key based server logins. **" \
--radiolist  --column "Pick" --column "Action" \
TRUE "Start ssh tunneling." \
FALSE "Enter your server data.");

	if [  "$ans" = "Start ssh tunneling." ]; then
		start_sshuttle

	elif [  "$ans" = "Enter your server data." ]; then
		save_data

	fi

