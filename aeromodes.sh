#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#Decode ACARS and VDL Mode 2, using acarsdec and vdlm2dec.  Both
#are capable of simultaneous multichannel reception, though each
#application must run one at a time on a device.

#-------------Set Variables----------------------------------------
#Designate up to eight ACARS frequencies, one per line, specified in MHz:
readarray -t afreq < /usr/local/etc/ACARS_FREQS
echo "Found the ACARS frequency list in ~/Documents/ACARS_FREQS: ${afreq[@]}"
#Designate up to eight vdl mode 2 frequencies, one per line specified in MHz:
readarray -t vfreq < /usr/local/etc/VDL_FREQS
echo "Found the VDL frequency list in ~/Documents/VDL_FREQS: ${vfreq[@]}"

#Specify the ACARS database file:
acarslog="$HOME/acarsserv.db"
#Specify the VDL2 database file:
vdl2log="$HOME/vdl2serv.db"

#-------------There be dragons below this line---------------------
#Get the SDR frequency offset (ppm)
ppm=$(cat /usr/local/etc/sdr_offset)
#Get the SDR gain (gain)
gain=$(cat /usr/local/etc/sdr_gain)
# Get the device key
devkey=$(cat /usr/local/etc/sdr_key)
#Take the number from the device key
key=$(echo $devkey | cut -f2 -d "=")

zero="0"
ans=$(zenity  --list  --title="RTLSDR Multichannel Digital Decoders" \
--height 430 --width 400 \
--text="ACARSdec and VDLM2dec functions:
-- ACARSdec decodes ACARS
-- VDLM2dec decodes VDL Mode 2
-- Several Channels at once
-- Error detection and correction
-- Can log messages to a database
-- SoapySDR or RTL-SDR hardware.

ACARS Frequencies:
$(echo ${afreq[@]})
VDL Mode 2 Frequencies:
Freqs: $(echo ${vfreq[@]})
" \
--radiolist --column "Select" \
FALSE "Run ACARSdec" \
FALSE "Run VDLM2dec" \
FALSE "Edit ACARS Frequencies" \
FALSE "Edit VDL Mode 2 Frequencies" \
TRUE "Stop ACARSdec or VDLM2dec" \
--column "Action");

if [  "$ans" = "Run ACARSdec" ]; then
	acarsdec -v -o 2 -j 127.0.0.1:5555 -g $gain$zero -p $ppm -r $key ${afreq[@]} &
	sleep 3
	acarsserv -v -j 127.0.0.1:5555 -b $acarslog -s &
	sleep 3
	sqlitebrowser $acarslog &
	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="ACARSdec - Running." \
	--text="The multi channel ACARS monitor is running.
To stop, use this application and select \"Stop ACARSdec.\"");

elif [  "$ans" = "Run VDLM2dec" ]; then
	vdlm2dec -v -J -G -E -j 127.0.0.1:5555 -g $gain$zero -p $ppm -r $key ${vfreq[@]} &
	sleep 3
	acarsserv -v -j 127.0.0.1:5555 -b $vdl2log -s &
	sleep 3
	sqlitebrowser $vdl2log &
	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="VDLM2dec - Running." \
	--text="The multi channel VDLM2 monitor is running.
To stop, use this application and select \"Stop VDLM2dec.\"");

elif [  "$ans" = "Edit ACARS Frequencies" ]; then
	mate-terminal -e "nano /usr/local/etc/ACARS_FREQS"

elif [  "$ans" = "Edit VDL Mode 2 Frequencies" ]; then
	mate-terminal -e "nano /usr/local/etc/VDL_FREQS"

elif [  "$ans" = "Stop ACARSdec or VDLM2dec" ]; then
	killall -9 vdlm2dec
	killall -9 acarsdec
	killall -9 acarsserv
	killall -9 sqlitebrowser
	exit

fi
