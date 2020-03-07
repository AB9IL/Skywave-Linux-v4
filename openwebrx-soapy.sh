#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#OpenWebRX for SDRPlay and other devices via rx_sdr

#Get the SDR frequency offset (ppm)
corr=$(cat /usr/local/etc/sdr_offset)
#Get the SDR gain (gain)
gain=$(cat /usr/local/etc/sdr_gain)
#Get the SoapySDR driver string
devdriver=$(cat /usr/local/etc/sdr_driver)
#Get the SoapySDR key number
devkey=$(cat /usr/local/etc/sdr_key)

cd /usr/local/sbin/openwebrx/

start() {
cp /usr/local/sbin/openwebrx/config_webrx.orig.py /usr/local/sbin/openwebrx/config_webrx.py
#Edit the configuration file.
sed -i "
     s/receiver_name =.*/receiver_name = \"Openwebrx in Skywave Linux\"/;
     s/receiver_location =.*/receiver_location = \"City, Country\"/;
     s/receiver_qra =.*/receiver_qra = \"GRIDLOC\"/;
     s/photo_height =.*/photo_height = 316/;
     s/photo_title =.*/photo_title = \"Scenery from the Interneational Space Station\"/;
     s/sdrhu_key =.*/sdrhu_key = \"$accountkey\"/;
     s/sdrhu_public_listing =.*/sdrhu_public_listing = $status/;
     s/fft_size =.*/fft_size = 8192/;
     s/real_input =.*/real_input = False/;
     s/samp_rate =.*/samp_rate = $samprate/;
     s/center_freq =.*/center_freq = $ctrfreq$mega/;
     s/rf_gain =.*/rf_gain = $gain/;
     s/ppm =.*/ppm = $corr/;
     s/audio_compression =.*/audio_compression = \"none\"/;
     s/fft_compression =.*/fft_compression = \"none\"/;
     s/client_audio_buffer_size =.*/client_audio_buffer_size = 10/;
     s/waterfall_min_level =.*/waterfall_min_level = -80/;
     s/waterfall_max_level =.*/waterfall_max_level = -20/;" /usr/local/sbin/openwebrx/config_webrx.py

# Append to the configuration file.
echo 'soapy_device_query = "driver='${devdriver}','${devkey}'"
start_rtl_command = "rx_sdr -d {device_query} -s {samp_rate} -f {center_freq} -p {ppm} -g {rf_gain} - ".format(device_query=soapy_device_query, rf_gain=rf_gain, center_freq=center_freq, samp_rate=samp_rate, ppm=ppm)
format_conversion = "csdr convert_u8_f"
start_mod = "'${mode}'"' >> /usr/local/sbin/openwebrx/config_webrx.py

#Start OpenWebRX
python2 ./openwebrx.py & firefox --new-tab http://localhost:8073/
}

notifyerror(){
        echo "Something went wrong!!!!!!"
        WINDOW=$(zenity --info --height 100 --width 350 \
		--title="Openwebrx - Error." \
		--text="Something went wrong!!!!!!");
        exit
}

OUTPUT=$(zenity --forms --title="OpenWebRX (SoapySDR)" \
--text="First, use the SDR Operating Parameters application
to enter your device type, PPM offset, and gain.  Then
fill in the fields below to start monitoring."\
--separator="," \
--add-entry="Frequency (MHz)" \
--add-entry="Mode (am,fm,usb,lsb,cw)" \
--add-entry="List on SDR.hu? (yes/no)");

if [[ "$?" -ne "0" ]]; then
    notifyerror
fi

ctrfreq=$(awk -F, '{print $1}' <<<$OUTPUT)
mode=$(awk -F, '{print $2}' <<<$OUTPUT)
status=$(awk -F, '{print $3}' <<<$OUTPUT)
mega=e6
samprate=1024000
accountkey=''

if [ "$status" == "yes" ]; then
OUTPUT2=$(zenity --forms --title="OpenWebRX (SoapySDR)" \
--add-entry="SDR.hu a ccount key:");

accountkey=$(awk -F, '{print $1}' <<<$OUTPUT2)

    if [[ "$?" -ne "0" || -z "$OUTPUT2" ]]; then
		notifyerror
	else
		status="True"
	fi
else
status="False"
fi

start
killall -9 openwebrx ncat nmux rtl_mus rtl_sdr csdr rx_sdr
pkill -f "python2 ./openwebrx.py"
exit
