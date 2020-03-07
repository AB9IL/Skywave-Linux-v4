#!/bin/bash

# Copyright (c) 2019 by Philip Collier, radio AB9IL <webmaster@ab9il.net>
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# Measure and save rtl-sdr calibration information using GSM base stations.
# Edit the file referenced for gain setting by certain applications.
# Save SoapySDR device string and key for other uses.

Encoding=UTF-8

get_offset(){
echo "Measuring ppm offset on channel "$best_channel
offset=($(kal -c $best_channel 2>&1 | grep "absolute error" | grep -Po "\d*\." | awk '{printf "%.0f", $0}'))

if [[ -z "$offset" ]]; then
		notifyerror
fi

echo $offset > /usr/local/etc/sdr_offset  # save offset for general usage
sed -i "s/corr_freq=.*/corr_freq=${offset}000000/g" ~/.config/gqrx/default.conf # save offset for gqrx

	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="Calibration and Gain" \
	--text="An offset of $offset ppm has been written to file /usr/local/etc/sdr_offset.");
}

notifyerror(){
	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="Calibration and Gain" \
	--text="Something went wrong.");
	exit
}

scan_band(){
echo "Please stand by.  Scanning for $band stations..."
mapfile -t arr < <(kal -v -s $band -g 40 2>&1 | grep 'chan:' | awk '{printf $2" "$7"\n"}' | sort -nrk2)
echo "Chan Strength"
printf '%s\n' "${arr[@]}"
set -- ${arr[0]}
best_channel=$1
get_offset
}

set_device(){
OUTPUT=$(zenity --forms --title="SoapySDR Device Type" --width 400 --height 100 \
--text="Enter the SDR start-up parameters
reported by \"SoapySDRUtil --find\"." \
--separator="," \
--add-entry="SoapySDR Device Driver (e.g. rtlsdr):" \
--add-entry="SoapySDR Device Key (e.g. rtl=0):" \
);

if [[ "$?" -ne "0" ]]; then
	notifyerror
fi

driver=$(awk -F, '{print $1}' <<<$OUTPUT)
devkey=$(awk -F, '{print $2}' <<<$OUTPUT)

# write device driver data to the reference file
echo $driver > /usr/local/etc/sdr_driver

# write device key to the reference file
echo $devkey > /usr/local/etc/sdr_key

	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="SoapySDR Device Type" \
	--text="Device driver $driver has been written to file /usr/local/etc/sdr_driver.
Device key $devkey has been written to file /usr/local/etc/sdr_key.");
}

setgain(){
OUTPUT=$(zenity --forms --title="Calibration and Gain" --width 400 --height 100 \
--text="Enter the desired SDR gain." \
--add-entry="Gain:");

if [[ "$?" -ne "0" || -z "$?" ]]; then
    exit
fi

gain=$(awk -F, '{print $1}' <<<$OUTPUT)

# write gain setting to the reference file
echo $gain > /usr/local/etc/sdr_gain

	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="Calibration and Gain" \
	--text="A gain of $gain has been written to file /usr/local/etc/sdr_gain.");
}

setoffset(){
OUTPUT=$(zenity --forms --title="Calibration and Gain" --width 400 --height 100 \
--text="Enter the desired SDR offset (ppm)." \
--add-entry="Offset:");

if [[ "$?" -ne "0" || -z "$?" ]]; then
    exit
fi

offset=$(awk -F, '{print $1}' <<<$OUTPUT)

echo $offset > /usr/local/etc/sdr_offset  # save offset for general usage
sed -i "s/corr_freq=.*/corr_freq=${offset}000000/g" ~/.config/gqrx/default.conf # save offset for gqrx

	WINDOW=$(zenity --info --height 100 --width 350 \
	--title="Calibration and Gain" \
	--text="An offset of $offset ppm has been written to file /usr/local/etc/sdr_offset.");
}

ans=$(zenity  --list  --title "SDR Operating Parameters" --width=500 --height=290 \
--text "Manage RTL-SDR frequency calibration and gain.
1) Calibration uses measurements of GSM base stations.
2) Device gain is saved for reference by other applications." \
--radiolist  --column "Pick" --column "Action" \
TRUE "Scan for GSM 850 MHz base stations." \
FALSE "Scan for GSM 900 MHz base stations." \
FALSE "Scan for E-GSM base stations." \
FALSE "Manually program the SDR offset." \
FALSE "Manually program the SDR gain." \
FALSE "Manually program the SoapySDR device data.");

	if [  "$ans" = "Scan for GSM 850 MHz base stations." ]; then
		band='GSM850'
		scan_band

	elif [  "$ans" = "Scan for GSM 900 MHz base stations." ]; then
		band='GSM900'
		scan_band

	elif [  "$ans" = "Scan for E-GSM base stations." ]; then
		band='EGSM'
		scan_band

	elif [  "$ans" = "Manually program the SDR offset." ]; then
		setoffset

	elif [  "$ans" = "Manually program the SDR gain." ]; then
		setgain

	elif [  "$ans" = "Manually program the SoapySDR device data." ]; then
		set_device

	fi

