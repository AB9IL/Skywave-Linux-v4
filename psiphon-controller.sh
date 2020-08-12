#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

psiphonstart(){
export http_proxy=127.0.0.1:8118
export https_proxy=127.0.0.1:8118
echo '//Set the proxy prefs
user_pref("network.proxy.ftp", "127.0.0.1");
user_pref("network.proxy.ftp_port", 8118);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 8118);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "127.0.0.1");
user_pref("network.proxy.socks_port", 1081);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 8118);
user_pref("network.proxy.type", 1);
user_pref("network.proxy.no_proxies_on", "localhost,127.0.0.1");' > /usr/local/etc/firefox/user.js
echo 'Acquire {
HTTP::proxy "http://127.0.0.1:8118";
HTTPS::proxy "http://127.0.0.1:8118";
}' > /etc/apt/apt.conf.d/proxy.conf
cd /usr/local/sbin/psiphon/
mate-terminal -e  'sh -c "echo \"Psiphon is connected if Tunnels {\"count\":1}. \
CTRL-C to exit Psiphon and clear the system proxy settings.\n\n\"; \
cd /usr/local/sbin/psiphon/ ; \
./psiphon-tunnel-core-x86_64 -config psiphon.config -serverList remote_server_list -formatNotices; read line"'
psiphonstop
}

psiphonstop(){
sudo killall psiphon-tunnel-core-x86_64
export http_proxy=
export https_proxy=
echo '//Clear the proxy prefs
user_pref("network.proxy.ftp", "");
user_pref("network.proxy.ftp_port", 0);
user_pref("network.proxy.http", "");
user_pref("network.proxy.http_port", 0);
user_pref("network.proxy.share_proxy_settings", false);
user_pref("network.proxy.socks", "");
user_pref("network.proxy.socks_port", 0);
user_pref("network.proxy.ssl", "");
user_pref("network.proxy.ssl_port", 0);
user_pref("network.proxy.type", 5);' > /usr/local/etc/firefox/user.js
rm -rf /etc/apt/apt.conf.d/proxy.conf
exit
}

set_any(){
sed -i "6s/.*/\"EgressRegion\":\"\",/" /usr/local/sbin/psiphon/psiphon.config

}

set_jp(){
sed -i "6s/.*/\"EgressRegion\":\"JP\",/" /usr/local/sbin/psiphon/psiphon.config
}

set_nl(){
sed -i "6s/.*/\"EgressRegion\":\"NL\",/" /usr/local/sbin/psiphon/psiphon.config
}

set_sg(){
sed -i "6s/.*/\"EgressRegion\":\"SG\",/" /usr/local/sbin/psiphon/psiphon.config
}


ans=$(zenity  --list  --title "PSIPHON CONTROLLER" --width=500 --height=245 \
--text "Start Psiphon and configure the system proxy settings.
Psiphon is connected if Tunnels {\"count\":1}.
CTRL-C to exit Psiphon and clear the system proxy settings." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Start Psiphon (best performing servers)." \
FALSE "Start Psiphon (egress from Japan)." \
FALSE "Start Psiphon (egress from the Netherlands)." \
FALSE "Start Psiphon (egress from Singapore).");

	if [  "$ans" = "Start Psiphon (best performing servers)." ]; then
		set_any
		psiphonstart

	elif [  "$ans" = "Start Psiphon (egress from Japan)." ]; then
		set_jp
		psiphonstart

	elif [  "$ans" = "Start Psiphon (egress from the Netherlands)." ]; then
		set_nl
		psiphonstart

	elif [  "$ans" = "Start Psiphon (egress from Singapore)." ]; then
		set_sg
		psiphonstart

	fi

