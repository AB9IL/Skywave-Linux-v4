#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Capture, decode, and save AIS data.
IFS=$'\n'
jsonfile=$HOME"/ais_log.json"
#Get the SDR frequency offset (ppm)
ppm=$(cat /usr/local/etc/sdr_offset)
#Get the SDR gain (gain)
gain=$(cat /usr/local/etc/sdr_gain)

dumpto_file() {
rtl_ais -p $ppm -g $gain &
nc 127.0.0.1 10110 | gpsdecode -j | tee -a $jsonfile &

WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - Running." \
--text="The dual channel AIS monitor is running.
To stop, use this application and select \"Stop AIS capture and logging.\""
);
}

dumpto_db(){
# open a database session, naming the db file
# get nmea data and pipe it through the converer to get json data
rtl_ais -p $ppm -g $gain &
nc 127.0.0.1 10110 | gpsdecode -j | ais-capturestream

WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - Running." \
--text="The dual channel AIS monitor is running.
To stop, use this application and select \"Stop AIS capture and logging.\""
);
}

readto_db() {
FILE=$(zenity --file-selection --title="RTL-AIS - Select File"
--text="Select a file containing raw NMEA sentences to decode.");

case $? in
	0)
		echo"\"$FILE\" selected.";;
	1)
		echo"No file selected.";;
	2)
		echo"Something went wrong...";;
esac

nmeafile=$FILE
# call the python script to read the file and build the database
mate-terminal -e "ais-fileto-sqlite $nmeafile"

WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - NMEA - Decode to Database." \
--text="The decoder process has run.  Look for a timestamped
\"...ais-decoded.db\" file.");
}

readto_json() {
FILE=$(zenity --file-selection --title="RTL-AIS - Select File with NMEA Data");
case $? in
	0)
		echo"\"$FILE\" selected."
		TIME=$(date +%Y-%m-%d_%H-%M-%S)
		nmeafile=$FILE
		# cat -> decode -> save
		cat $nmeafile | gpsdecode | tee $TIME'-ais-decoded.json'

		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to JSON." \
		--text="The decoder process has run; \"...-ais-decoded.json\" written.")
		;;
	1)
		echo"No file selected."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to JSON." \
		--text="No file selected; no decoding accomplished.")
		;;
	2)
		echo"Something went wrong..."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to JSON." \
		--text="Something went wrong; no decoding accomplished.")
		;;
esac
}

startmapper() {
WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - Reserved." \
--text="This selection is reserved for future use"
);
}

stopcapture() {
killall rtl_ais nc
}

ans=$(zenity  --list  --title "AIS MONITOR" --width=600 --height=280 \
--text "Manage capture and plotting of AIS data." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Capture AIS NMEA sentences by radio, decode, and write to a logfile."  \
FALSE "Capture AIS NMEA sentences by radio, decode, and write to a database." \
FALSE "Read a file containing AIS NMEA sentences, decode, and write to a database." \
FALSE "Read a file containing AIS NMEA sentences, decode, and write to a json file." \
FALSE "Plot AIS database info on a map." \
TRUE "Stop AIS capture and logging.");

	if [  "$ans" = "Capture AIS NMEA sentences by radio, decode, and write to a logfile." ]; then
		dumpto_file

	elif [  "$ans" = "Capture AIS NMEA sentences by radio, decode, and write to a database." ]; then
		dumpto_db

	elif [  "$ans" = "Read a file containing AIS NMEA sentences, decode, and write to a database." ]; then
		readto_db

	elif [  "$ans" = "Read a file containing AIS NMEA sentences, decode, and write to a json file." ]; then
		readto_json

	elif [  "$ans" = "Plot AIS database info on a map." ]; then
		startmapper

	elif [  "$ans" = "Stop AIS capture and logging." ]; then
		stopcapture

	fi
