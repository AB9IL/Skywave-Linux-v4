#!/bin/sh

# Copyright (c) 2019 by Philip Collier, <webmaster@catbirdlinux.com>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Encoding=UTF-8

lanternstart(){
export https_proxy=127.0.0.1:8118
export HTTPS_PROXY=127.0.0.1:8118
export http_proxy=127.0.0.1:8118
export HTTP_PROXY=127.0.0.1:8118
export socks_proxy=127.0.0.1:31519
export SOCKS_PROXY=127.0.0.1:31519
export NO_PROXY='localhost, 127.0.0.1'
export no_proxy='localhost, 127.0.0.1'
echo '//configure the proxy prefs
user_pref("network.proxy.ftp", "");
user_pref("network.proxy.ftp_port", 0);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 8118);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks", "127.0.0.1");
user_pref("network.proxy.socks_port", 31519);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 8118);
user_pref("network.proxy.type", 1);
user_pref("network.proxy.no_proxies_on", "localhost,127.0.0.1");' > /usr/local/etc/firefox/user.js
sh -c "lantern -obfs4-distBias -addr 127.0.0.1:8118 -socksaddr 127.0.0.1:31519"
lanternstop
}

lanternstop(){
sudo killall lantern
export https_proxy=
export HTTPS_PROXY=
export http_proxy=
export HTTP_PROXY=
export socks_proxy=
export SOCKS_PROXY=
export NO_PROXY=
export no_proxy=
echo '//clear the proxy prefs
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

lanternstart
