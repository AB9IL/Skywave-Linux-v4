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
fifo='/tmp/ais.dump'

dumpto_file() {
# create a pipe
mkfifo -m 666 $fifo
# start reading from the pipe
cat $fifo | gpsdecode -j | tee -a $jsonfile &
# feed the pipe
rtl_ais -p $ppm -g $gain &
nc 127.0.0.1 10110 > $fifo

WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - Running." \
--text="The dual channel AIS monitor is running.
To stop, use this application and select \"Stop AIS capture and logging.\""
);
}

dumpto_db(){
# create a pipe
mkfifo -m 666 $fifo
# call the python script to read the pipe and build the database
sh -c "ais-fileto-sqlite $fifo"
# get nmea data and feed the pipe
rtl_ais -p $ppm -g $gain &
nc 127.0.0.1 10110 > $fifo

WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - Running." \
--text="The dual channel AIS monitor is running.
To stop, use this application and select \"Stop AIS capture and logging.\""
);
}

readto_db() {
FILE=$(zenity --file-selection --title="RTL-AIS - Select File" \
--text="Select a file containing raw NMEA sentences to decode.");

case $? in
	0)
		echo "$FILE selected.";;
	1)
		echo "No file selected."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to Database." \
		--text="No file selected; no decoding accomplished.")
		exit;;
	2)
		echo "Something went wrong..."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to Database." \
		--text="No file selected; no decoding accomplished.")
		exit;;
esac

nmeafile=$FILE
# call the python script to read the file and build the database
sh -c "ais-fileto-sqlite $nmeafile"

WINDOW=$(zenity --info --height 100 --width 350 \
--title="RTL-AIS - NMEA - Decode to Database." \
--text="The decoder process has run.  Look for a timestamped
\"...ais-decoded.db\" file.");
}

readto_json() {
FILE=$(zenity --file-selection --title="RTL-AIS - Select File with NMEA Data");
case $? in
	0)
		echo "\"$FILE\" selected."
		TIME=$(date +%Y-%m-%d_%H-%M-%S)
		nmeafile=$FILE
		# cat -> decode -> save
		cat $nmeafile | gpsdecode | tee $TIME'-ais-decoded.json'

		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to JSON." \
		--text="The decoder process has run; \"...-ais-decoded.json\" written.")
		;;
	1)
		echo "No file selected."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to JSON." \
		--text="No file selected; no decoding accomplished.")
		exit
		;;
	2)
		echo "Something went wrong..."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - NMEA - Decode to JSON." \
		--text="Something went wrong; no decoding accomplished.")
		exit
		;;
esac
}

startmapper() {
# Select the json file to send to the mapper
FILE=$(zenity --file-selection --title="RTL-AIS - Select Json File with AIS Data");
case $? in
	0)
		echo "\"$FILE\" selected."
		jsonfile=$FILE
		ais-mapper $jsonfile

		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - Mapper Starting." \
		--text="Data has been sent to the mapper.")
		;;
	1)
		echo "No file selected."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - Mapping Failed: No File Selected" \
		--text="No file selected; no map plotting possible.")
		exit
		;;
	2)
		echo "Something went wrong..."
		WINDOW=$(zenity --info --height 100 --width 350 \
		--title="RTL-AIS - Mapping Failed: Something Went Wrong" \
		--text="Something went wrong; no mapping accomplished.")
		exit
		;;
esac

}

stopcapture() {
killall rtl_ais nc
rm -f $fifo
}

ans=$(zenity  --list  --title "AIS MONITOR" --width=600 --height=280 \
--text "Manage capture and plotting of AIS data." \
--radiolist  --column "Pick" --column "Action" \
FALSE "Capture AIS NMEA sentences by radio, decode, and write to a logfile."  \
FALSE "Capture AIS NMEA sentences by radio, decode, and write to a database." \
FALSE "Read a file containing AIS NMEA sentences, decode, and write to a database." \
FALSE "Read a file containing AIS NMEA sentences, decode, and write to a json file." \
FALSE "Plot decoded AIS info on a map." \
TRUE "Stop AIS capture and logging.");

[[ "$ans" == "Capture AIS NMEA sentences by radio, decode, and write to a logfile." ]] && dumpto_file
[[ "$ans" == "Capture AIS NMEA sentences by radio, decode, and write to a database." ]] && dumpto_db
[[ "$ans" == "Read a file containing AIS NMEA sentences, decode, and write to a database." ]] && readto_db
[[ "$ans" == "Read a file containing AIS NMEA sentences, decode, and write to a json file." ]] && readto_json
[[ "$ans" == "Plot decoded AIS info on a map." ]] && startmapper
[[ "$ans" == "Stop AIS capture and logging." ]] && stopcapture
