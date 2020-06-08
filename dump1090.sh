#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Capture, decode, and save ADS-B data.

#Get the SDR frequency offset (ppm)
ppm=$(cat /usr/local/etc/sdr_offset)
#Get the SDR gain (gain)
gain=$(cat /usr/local/etc/sdr_gain)
#Get the SoapySDR driver string
devdriver=$(cat /usr/local/etc/sdr_driver)
#Get the SoapySDR key number
devkey=$(cat /usr/local/etc/sdr_key)

startlog() {
# run dump1090
mkfifo /tmp/1090.dump
sleep 1
rx_sdr -f 1090000000 -s 2048000 -p $ppm -g $gain -d driver=$devdriver','$devkey /tmp/1090.dump | dump1090 --net --net-sbs-port=30003 &
sleep 1
nc 127.0.0.1 30003 | egrep --line-buffered 'MSG,1|MSG,3|MSG,4|MSG,6' >> $HOME/adsb.log &
}

start_decoded_log() {
# run dump1090
rx_sdr -f 1090000000 -s 2048000 -p $ppm -g $gain -d driver=$devdriver','$devkey /tmp/1090.dump | dump1090 --net --net-sbs-port=30003 &
sleep 1
/usr/local/bin/dump1090-stream-parser &
sleep 1
sqlitebrowser $HOME/adsb_messages.db &
}

startplot() {
OUTPUT=$(zenity --forms --title="Dump1090 (SoapySDR)" \
--text="Enter the geographical coordinates (degrees and decimals).
For example, in New York you enter latitude 40.7, longitude -74.0." \
--separator="," \
--add-entry="Latitude (degrees.decimals)" \
--add-entry="Longitude (degrees.decimals)");

if [[ "$?" -ne "0" || -z "$?" ]]; then
    stop
    notifyerror
    exit
fi

latitude=$(awk -F, '{print $1}' <<<$OUTPUT)
longitude=$(awk -F, '{print $2}' <<<$OUTPUT)

cp /usr/local/sbin/dump1090/public_html/config.js.orig /usr/local/sbin/dump1090/public_html/config.js
# edit the config file with actual lat/lon
sed -i "
     27s/.*/DefaultCenterLat = $latitude;/ ;
     28s/.*/DefaultCenterLon = $longitude;/ ;
     36s/.*/SiteLat = $latitude;/ ;
     37s/.*/SiteLon = $longitude;/" /usr/local/sbin/dump1090/public_html/config.js

# run dump1090
rx_sdr -f 1090000000 -s 2048000 -p $ppm -g $gain -d driver=$devdriver','$devkey /tmp/1090.dump | dump1090 --net --net-sbs-port=30003 --ifile=/tmp/1090.dump &
# Stop here...fix this to use python mapping scripts.
WINDOW=$(zenity --info --height 100 --width 350 \
--title="Dump1090 - Reserved." \
--text="This selection is reserved for future use");
}

notifyerror(){
        echo "Something went wrong!!!!!!"
        WINDOW=$(zenity --info --height 100 --width 350 \
		--title="Dump1090 - Error." \
		--text="Something went wrong!!!!!!");
        exit
}

stop(){
killall -9 dump1090 rx_sdr nc sqlitebrowser
pkill -f /usr/local/bin/dump1090-stream-parser
exit
}

ans=$(zenity  --list  --title "Dump1090" --height=275 --width=450 \
--text "Manage ADS-B logging and plotting.
First, use the SDR Operating Parameters application
to enter your device type, PPM offset, and gain.
Select a monitoring action from the list below." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Start Dump1090 and write raw data to a logfile." \
FALSE "Start Dump1090 and write decoded data to a database." \
FALSE "Start Dump1090 and plot aircraft positions." \
TRUE "Stop Dump1090");

	if [  "$ans" = "Start Dump1090 and write raw data to a logfile." ]; then
		startlog

	elif [  "$ans" =  "Start Dump1090 and write decoded data to a database." ]; then
		start_decoded_log

	elif [  "$ans" = "Start Dump1090 and plot aircraft positions." ]; then
		startplot

	elif [  "$ans" = "Stop Dump1090" ]; then
		stop

	fi

