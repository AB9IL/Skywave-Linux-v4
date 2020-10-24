#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

psiphonstart(){
export https_proxy=127.0.0.1:8118
export HTTPS_PROXY=127.0.0.1:8118
export http_proxy=127.0.0.1:8118
export HTTP_PROXY=127.0.0.1:8118
export socks_proxy=127.0.0.1:31519
export SOCKS_PROXY=127.0.0.1:31519
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
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
x-terminal-emulator -e bash -c "echo \"Psiphon is connected if Tunnels {\"count\":1}.
CTRL-C to exit Psiphon and clear the system proxy settings.\"; \
echo\"\"; cd /usr/local/sbin/psiphon/; \
./psiphon-tunnel-core-x86_64 -config psiphon.config \
-serverList remote_server_list -formatNotices; read line"
psiphonstop
}

psiphonstop(){
sudo killall psiphon-tunnel-core-x86_64
export https_proxy=
export HTTPS_PROXY=
export http_proxy=
export HTTP_PROXY=
export socks_proxy=
export SOCKS_PROXY=
export NO_PROXY=
export no_proxy=
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
sed -i "
	s/http_proxy.*/http_proxy/g
	s/https_proxy.*/https_proxy/g
	s/no_proxy.*/no_proxy/g" ~/.w3m/config
exit
}

set_any(){
sed -i "s/EgressRegion.*/EgressRegion\":\"\",/" /usr/local/sbin/psiphon/psiphon.config
}

set_fr(){
sed -i "s/EgressRegion.*/EgressRegion\":\"FR\",/" /usr/local/sbin/psiphon/psiphon.config
}

set_jp(){
sed -i "s/EgressRegion.*/EgressRegion\":\"JP\",/" /usr/local/sbin/psiphon/psiphon.config
}

set_nl(){
sed -i "s/EgressRegion.*/EgressRegion\":\"NL\",/" /usr/local/sbin/psiphon/psiphon.config
}

set_sg(){
sed -i "s/EgressRegion.*/EgressRegion\":\"SG\",/" /usr/local/sbin/psiphon/psiphon.config
}


ans=$(zenity  --list  --title "PSIPHON CONTROLLER" --width=500 --height=300 \
--text "Start Psiphon and configure the system proxy settings.
Psiphon is connected if Tunnels {\"count\":1}.
CTRL-C to exit Psiphon and clear the system proxy settings." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Start Psiphon (best performing servers)." \
FALSE "Start Psiphon (egress from France)." \
FALSE "Start Psiphon (egress from Japan)." \
FALSE "Start Psiphon (egress from the Netherlands)." \
FALSE "Start Psiphon (egress from Singapore).");

[[ "$ans" == "Start Psiphon (best performing servers)." ]] && set_any && psiphonstart;
[[ "$ans" == "Start Psiphon (egress from France)." ]] && set_fr && psiphonstart;
[[ "$ans" == "Start Psiphon (egress from Japan)." ]] && set_jp && psiphonstart;
[[ "$ans" == "Start Psiphon (egress from the Netherlands)." ]] && set_nl && psiphonstart;
[[ "$ans" == "Start Psiphon (egress from Singapore)." ]] && set_sg && psiphonstart;
