#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Capture a wide RF bandwidth and operate a multichannel SDR receiver.

streamname="RTLSDR-Airband Multichannel"
genre="Voice Communicatons"
#Get the SDR frequency offset (ppm)
corr=$(cat /usr/local/etc/sdr_offset)
#Get the SDR gain (gain)
gain=$(cat /usr/local/etc/sdr_gain)
#Get the SoapySDR driver string
devdriver=$(cat /usr/local/etc/sdr_driver)
#Get the SoapySDR key number
devkey=$(cat /usr/local/etc/sdr_key)
#Get the frequency and mode list
readarray FREQLIST < ~/Documents/VOICE_FREQS

# compute the median frequency here...
MYLIST=()
for thefreq in ${FREQLIST[@]}; do
	a=$(echo $thefreq | cut -f1 -d ",")
	MYLIST+=("${a}")
done

IFS=$'\n'
ctrfreq=$(awk '{arr[NR]=$1} END {if (NR%2==1) print arr[(NR+1)/2]; \
else print (arr[NR/2]+arr[NR/2+1])/2}' <<< sort <<< "${MYLIST[*]}")

# Format the center frequency the SDR will use
ctrfreq=$(printf "%8.2f\n" "$ctrfreq")

echo "Found the frequency list in ~/Documents/VOICE_FREQS: ${FREQLIST[@]}"
echo "Median frequency is ${ctrfreq}"
unset IFS

# The number of channels
channels=${#MYLIST[@]}

start0(){
#start rtlsdr-airband on PulseAudio
cp -f /usr/local/etc/rtl_airband-pulse.conf /usr/local/etc/rtl_airband.conf
/usr/local/bin/rtl_airband &
WINDOW=$(zenity --info --height 100 --width 350 \
--title="Multichannel Voice - Running" \
--text="The multichannel receiver is running.
To stop, use this application and select \"Stop Multichannel Voice.\""
);
}

start1(){
#start rtlsdr-airband on the icecast server
cp -f /usr/local/etc/rtl_airband-icecast.conf /usr/local/etc/rtl_airband.conf
service icecast2 start
sleep 3
#start rtlsdr-airband
/usr/local/bin/rtl_airband &
sleep 3
firefox --new-tab http://127.0.0.1:8000
stop
}

start2(){
#build the config file for using PulseAudio
buildconf0
# copy the new config file
cp -f /usr/local/etc/rtl_airband-pulse.conf /usr/local/etc/rtl_airband.conf
#start rtlsdr-airband
/usr/local/bin/rtl_airband &
WINDOW=$(zenity --info --height 100 --width 350 \
--title="Multichannel Voice - Running" \
--text="The multichannel receiver is running.
To stop, use this application and select \"Stop Multichannel Voice.\""
);
}

start3(){
#build the config file for using icecast
buildconf1
cp -f /usr/local/etc/rtl_airband-icecast.conf /usr/local/etc/rtl_airband.conf
#start rtlsdr-airband
service icecast2 start
sleep 3
#start rtlsdr-airband
/usr/local/bin/rtl_airband &
sleep 3
firefox --new-tab http://127.0.0.1:8000
}

stop(){
#stop rtlsdr-airband
killall rtl_airband
#stop the icecast2 server
service icecast2 stop
sleep 2
echo "STOPPED RTLSDR-Airband. Alpha Mike Foxtrot..."
exit
}

buildconf0(){
# data and config for PulseAudio
#top of the file, defining SDR tuning, etc
echo '# This is a sample configuration file for RTLSDR-Airband.
# Just a single SDR with multiple AM channels in multichannel mode.
# Each channel is sent to PulseAusio. Settings are described
# in reference.conf.

mixers: {
  mixer1: {
    outputs: (
        {
	      type = "pulse";
          stream_name = "'$streamname'";
          genre = "'$genre'";
	}
    );
  }
};

devices:
({
  type = "soapysdr";
  device_string = "driver='$devdriver',device_id='$devkey'";
  gain = '$gain';
  centerfreq = '$ctrfreq';
  correction = '$corr';
  channels:
  (' > /usr/local/etc/rtl_airband-pulse.conf

#write the channel and mode confifig data here...
n=1
comma=","
for thechannel in ${FREQLIST[@]}; do
freq=$(echo $thechannel | cut -f1 -d ",")
mode=$(echo $thechannel | cut -f2 -d ",")

if (( $n == $channels )); then
     comma=""
fi

# for multiple channels use stereo
if [[ $(( $n % 2 )) -eq 0 ]];
	then bal="+0.6" ;
	else bal="-0.6" ;
fi

# for one channel use mono
if (( $channels == 1 ));
	then bal="0.0"
fi

# middle of the file, defining channels and outputs
echo '    {
      freq = '$freq';
      mode = "'$mode'";
      outputs: (
    {
	  type = "mixer";
	  name = "mixer1";
	  balance = '$bal';
	}
      );
    }'$comma >> /usr/local/etc/rtl_airband-pulse.conf
let "n++"
done

#bottom of the file
echo "  );
 }
);" >> /usr/local/etc/rtl_airband-pulse.conf

}

buildconf1(){
# data and config for icecast
#top of the file, defining SDR tuning, etc
echo '# This is a sample configuration file for RTLSDR-Airband.
# Just a single SDR with multiple AM channels in multichannel mode.
# Each channel is sent to the Icecast server. Settings are described
# in reference.conf.

mixers: {
  mixer1: {
    outputs: (
        {
	      type = "icecast";
	      server = "localhost";
          port = 8000;
          mountpoint = "mixer1.mp3";
          stream_name = "'$streamname'";
          genre = "'$genre'";
          username = "source";
          password = "skywave";
	}
    );
  }
};

devices:
({
  type = "soapysdr";
  device_string = "driver='$devdriver',device_id='$devkey'";
  gain = '$gain';
  centerfreq = '$ctrfreq';
  correction = '$corr';
  channels:
  (' > /usr/local/etc/rtl_airband-icecast.conf

#write the channel and mode confifig data here...
n=1
comma=","
for thechannel in ${FREQLIST[@]}; do
freq=$(echo $thechannel | cut -f1 -d ",")
mode=$(echo $thechannel | cut -f2 -d ",")

if (( $n == $channels )); then
     comma=""
fi

# for multiple channels use stereo
if [[ $(( $n % 2 )) -eq 0 ]];
	then bal="+0.6" ;
	else bal="-0.6" ;
fi

# for one channel use mono
if (( $channels == 1 ));
	then bal="0.0"
fi

# middle of the file, defining channels and outputs
echo '{
      freq = '$freq';
      mode = "'$mode'";
      outputs: (
    {
	  type = "mixer";
	  name = "mixer1";
	  balance = '$bal';
	}
      );
    }'$comma >> /usr/local/etc/rtl_airband-icecast.conf

let "n++"
done

#bottom of the file
echo '  );
 }
);' >> /usr/local/etc/rtl_airband-icecast.conf
}

backupconf(){
cp -f /usr/local/etc/rtl_airband.conf /usr/local/etc/rtl_airband.conf.bak
}

restoreconf(){
cp -f /usr/local/etc/rtl_airband.conf.bak /usr/local/etc/rtl_airband.conf
}

notifyerror(){
        echo "Something went wrong!!!!!!"
        WINDOW=$(zenity --info --height 100 --width 350 \
		--title="Multicgannel Voice - Error." \
		--text="Something went wrong!!!!!!");
}

ans=$(zenity --list --title "Multichannel Voice" --height 420 --width 500 \
--text "Multichannel Voice functions:
--Uses SoapySDR drivers
--Simultaneous multichannel demodulation
--Set demodulation independently per channel
--Stereo mixing for for multiple channels
--Softwaare powered by \"RTLSDR-Airband\"
--Edit the frequencies in ~/Documents/VOICE_FREQS
  The format is one frequency and mode per line, comma separated.

" \
--radiolist  --column "Pick" --column "Action" \
TRUE "Start Multichannel Voice (PulseAudio)" \
FALSE "Start Multichannel Voice (Icecast)" \
FALSE "Set channels and start Multichannel Voice (PulseAudio)" \
FALSE "Set channels and start Multichannel Voice (Icecast)" \
FALSE "Backup the current config file." \
FALSE "Restore the config file from a backup." \
FALSE "Stop Multichannel Voice" \
);

	if [  "$ans" = "Start Multichannel Voice (PulseAudio)" ]; then
		start0

	elif [  "$ans" = "Start Multichannel Voice (Icecast)" ]; then
		start1

	elif [  "$ans" = "Set channels and start Multichannel Voice (PulseAudio)" ]; then
		start2

	elif [  "$ans" = "Set channels and start Multichannel Voice (Icecast)" ]; then
		start3

	elif [  "$ans" = "Backup the current config file." ]; then
		backupconf

	elif [  "$ans" = "Restore the config file from a backup." ]; then
		restoreconf

	elif [  "$ans" = "Stop Multichannel Voice" ]; then
		stop

	fi

