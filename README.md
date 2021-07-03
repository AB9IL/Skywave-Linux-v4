# Skywave-Linux-v4
Scripts providing efficient, powerful, yet user friendly software defined radio operation in Skywave Linux v4.

#### aeromodes.sh:
Requires acarsdec and vdlm2dec.  Simultaneous and multichannel ACARS or VDL Mode 2 data capture.

#### ais-file-decoder:
Requires python3 with modules ais and json.  AIS file decoder converts logs of NMEA data to decoded json format.

#### ais-fileto-sqlite:
Requires python3 and modules ais, sqlite3, and json. AIS file decoder converts logs of NMEA data to an sqlite database file.

#### ais-mapper:
Requires python3 and modules folium, pandas, and numpy. 

#### ais_monitor.sh:
Requires rtl-ais.  Simultaneous dual channel ais maritime data capture.  The ais-mapper reads a file of decoded NMEA sentences containing AIS data, builds a dataframe, and plots vessels according to mmsi, name, latitude, and longitude.

#### dump1090.sh:
Requires dump1090 and dump1090-stream-parser.  Capture, parse, and save aeronautical ADS-B data.

#### sdr-params.sh:
Requires kalibrate-rtl.  Store SDR parameters for use by other applications and also measure rtl-sdr frequency offsets (the error in ppm).  Manually enter the soapysdr device string and index.  This script makes it convenient for dump1090, rtl_fm, or other to read what you want to use for gain or have for a ppm offset.  You must put code to fetch the data into those other scripts.

#### lantern-controller.sh:
Requires Lantern.  Configures Firefox networking settings and starts / stops Lantern such that it runs on specific ports and is terminated cleanly.

#### make-podcast:
Requires FFMPEG.  Trims and processes audio for easier podcast creation.

#### make-screencast:
Requires FFMPEG.  Trims and processes video for easier screencast creation.

#### nanoer.sh:
Requires nano.  Force nano to run in a specific terminal emulator, set up command arguments.

#### nvimmer.sh:
Requires neovim.  Force nvim to run in a specific terminal emu;ator, set up cammand arguments.

#### openwebrx-soapy.sh:
Requires Python, CSDR, OpenWebRX.  Simplify legacy OpenwebRX SDR on SoapySDR compatible devices.
Note:  Likely to be removed from Skywave Linux v4.0

#### openwebrx-soundcard.sh:
Requires Python, CSDR, OpenWebRX.  Simplify legacy OpenwebRX SDR on the computer audio interface.
Note:  Likely to be removed from Skywave Linux v4.0

#### openwebrx-vlf.sh:
Requires Python, CSDR, OpenWebRX.  Simplify legacy OpenwebRX SDR on audio-based VLF receivers.
Note:  Likely to be removed from Skywave Linux v4.0

#### psiphon-controller.sh
Requires psiphon-tunnel-core.  Tunneling application for using Psiphon anti-censorship tools on Linux.

#### rtlsdr-airband.sh:
Requires RTLSDR-Airband.  Simultaneous multichannel am or nbfm voice reception.

#### sdr-bookmarks:
Requires Rofi and / or fzf.  Reads a list of radio bookmarks to tune on your local RTL-SDR.  It presents a "fuzzy finder" style menu.  When a frequency is selected, rtl_fm tunes to it and drops into the background to provide audio.  Bring up the menu again to select another frequency or stop reception.  The radio bookmarks are stored in the file "sdrbookmarks" located in the ~/Music directory.  Entries are one per line, formatted in order of "frequency mode description" with the description in quotes.  There is a menu option for editing the list.

#### sdr-stream:
Requires Rofi and / or fzf.  Provide easy and rapid access to favorite stations on WebSDR or KiwiSDR servers.  Supports simultaneous "multi site" monitoring.

#### sshuttle-controller.sh:
Requires sshuttle and Rofi or fzf.  SSH tunneling application for anti-censorship when VPNs are being blocked.  It now presents a menu from which the user selects from multiple servers (or different accounts on one server).  The server list is written to ~/.config/sshuttle/sshuttle.conf.  Each line should contain three space separated fields: ip-address username port.  Call the script with no arguments to run in CLI mode with fzf; add the argument "gui" to use Rofi.

#### vimwiki:
Requires Neovim with Vimwiki plugin.  Take notes in markdown format, fully linkable and searchable.

#### vlc-playlist:
Rewritten for 2021! Requires VLC and Rofi or fzf.  Reads playlist of streaming audio broadcasters and presents a "fuzzy finder" style menu.  When a sation is selected, the application drops into the backgound to provide audio.  Bring up the menu again to select another station or stop streaming.  Amplitude compression is enabled by default to to make loudness more consistent across the various streams.  The playlist is contained in the file "radiostreams" and it is normally kept in the ~/Music directory.  Entries are one line per stream; url and quoted name of the station, and there is an option in the menu for editing the list.
