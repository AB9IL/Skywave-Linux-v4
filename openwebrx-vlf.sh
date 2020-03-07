#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

#OpenWebRX for softrocks / soundcard based SDRs for VLF

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
     s/real_input =.*/real_input = True/;
     s/samp_rate =.*/samp_rate = $adcrate/;
     s/center_freq =.*/center_freq = $cfreq/;
     s/audio_compression =.*/audio_compression = \"none\"/;
     s/fft_compression =.*/fft_compression = \"none\"/;
     s/client_audio_buffer_size =.*/client_audio_buffer_size = 10/;
     s/waterfall_min_level =.*/waterfall_min_level = -95/;
     s/waterfall_max_level =.*/waterfall_max_level = -5/;" /usr/local/sbin/openwebrx/config_webrx.py

# Append to the configuration file.
echo 'start_rtl_command="arecord -D default -f S16_LE -r {samp_rate} -c2 - ".format(samp_rate=samp_rate)
format_conversion="csdr convert_s16_f | csdr gain_ff 30"
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

OUTPUT=$(zenity --forms --title="OpenWebRX - VLF" --text="Enter the SDR start-up parameters." \
--separator="," --add-entry="Mode (am,fm,usb,lsb,cw)" --add-entry="ADC sample rate (44100,48000,96000,192000)" --add-entry="List on SDR.hu? (yes/no)");

if [[ "$?" -ne "0" ]]; then
	notifyerror
fi

mode=$(awk -F, '{print $1}' <<<$OUTPUT)
adcrate=$(awk -F, '{print $2}' <<<$OUTPUT)
status=$(awk -F, '{print $3}' <<<$OUTPUT)
mega=e6
accountkey=''
cfreq=$( echo 'print(int('${adcrate}' / 4  ))' | python3) #  do mathematics with python3

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
killall -9 openwebrx ncat nmux rtl_mus rtl_sdr csdr arecord
pkill -f "python2 ./openwebrx.py"
exit
