#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#Decode ACARS and VDL Mode 2, using acarsdec and dumpvdl2.  Both
#are capable of simultaneous multichannel reception, though each
#application must run one at a time on a device.

#-------------Set Variables----------------------------------------
#Designate up to eight ACARS frequencies, specified in MHz:
afreq=$(cat ~/Documents/ACARS_FREQS)

#Designate up to eight vdl mode 2 frequencies, specified in MHz:
vfreq=$(cat ~/Documents/VDL_FREQS)

#Specify the ACARS database file:
acarslog="~/acarsserv.db"
#Specify the VDL2 database file:
vdl2log="~/vdl2serv.db"

#-------------There be dragons below this line---------------------
#Get the SDR frequency offset (ppm)
ppm=$(cat /usr/local/etc/sdr_offset)
#Get the SDR gain (gain)
gain=$(cat /usr/local/etc/sdr_gain)

ans=$(zenity  --list  --title="RTLSDR Multichannel Digital Decoders" \
--height 370 --width 350 \
--text="ACARSdec and VDLM2dec functions:
-- ACARSdec decodes ACARS
-- VDLM2dec decodes VDL Mode 2
-- Several Channels at once
-- Error detection and correction
-- Can log messages to a database
-- SoapySDR or RTL-SDR hardware.
-- Edit ACARS Frequencies in ~/Documents/ACARS_FREQS
-- Edit VDL Frequencies in ~/Documents/VDL_FREQS
" \
--radiolist --column "Select" TRUE "Run ACARSdec" FALSE "Run VDLM2dec" \
FALSE "Stop ACARSdec" FALSE "Stop VDLM2dec" --column "Action");

if [  "$ans" = "Run ACARSdec" ]; then
	 killall -9 acarsdec
	 killall -9 acarsserv

	sh -c "acarsserv -v -j 127.0.0.1:5555 -b ${acarslog} -s" &
	sleep 3
	sh -c "acarsdec -v -o 2 -j 127.0.0.1:5555 -g ${gain}0 -p 0${ppm} -r 0 ${afreq[*]}" &
	sleep 3
	sh -c "sqlitebrowser ${acarslog}" &
	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="ACARSdec - Running." \
	--text="The multi channel ACARS monitor is running.  To stop, use this application and select \"Stop ACARSdec.\"");


elif [  "$ans" = "Run VDLM2dec" ]; then
	 killall -9 dumpvdl2
	 touch $vdl2log

	sh -c "acarsserv -v -j 127.0.0.1:5555 -b ${vdl2log} -s" &
	sleep 3
	sh -c "vdlm2dec -v -J -G -E -j 127.0.0.1:5555 -g ${gain}0 -p 0${ppm} -r 0 ${vfreq[*]}" &
	sleep 3
	sh -c "sqlitebrowser ${vdl2log}" &
	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="VDLM2dec - Running." \
	--text="The multi channel VDLM2 monitor is running.  To stop, use this application and select \"Stop VDLM2dec.\"");


elif [  "$ans" = "Stop ACARSdec" ]; then
	 killall -9 acarsdec
	 killall -9 acarsserv
	 killall -9 sqlitebrowser
	 exit
	 
elif [  "$ans" = "Stop VDLM2dec" ]; then
	 killall -9 vdlm2dec
	 killall -9 acarsserv
	 killall -9 sqlitebrowser
	 exit

fi

