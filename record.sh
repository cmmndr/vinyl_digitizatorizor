#!/bin/bash

# Check dependencies
command -v sox >/dev/null 2>&1 || { 
    echo "sox not installed. Install via sudo apt-get install sox or your preferred paket manager way"; 
    exit 1; 
}

# First run check
function init_check{
	STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/vinyl_digitizatorizor/"
    STATE_FILE="$STATE_DIR/initialized"

	if [ ! -f "$STATE_FILE" ]; then
    		echo "Vinyl Digitizatorizor has not yet been run, initializing..."
    		mkdir -p "$STATE_DIR"
    		touch "$STATE_FILE"
            change_capturing_device
    fi
	
}



# Start recording for automated clipping
function start_recording_auto_clip {
    # Interpret und Album abfragen
    read -p "Bitte gib den Interpreten ein: " ARTIST
    ARTIST_CLEAN=$(echo "$ARTIST" | sed 's/[^a-zA-Z0-9äöüÄÖÜß ]/-/g')
    read -p "Bitte gib den Albumnamen ein: " ALBUM
    ALBUM_CLEAN=$(echo "$ALBUM" | sed 's/[^a-zA-Z0-9äöüÄÖÜß ]/-/g')

    # Anzahl der Tracks abfragen
    read -p "Wie viele Tracks hat das Album? " TRACK_COUNT

    # Tracknamen abfragen und speichern
    TRACK_NAMES=()
    for ((i=1; i<=TRACK_COUNT; i++)); do
        read -p "Name von Track $i: " TRACK_NAME
        TRACK_NAMES+=("$TRACK_NAME")
    done

    # Verzeichnis erstellen
    RECORDING_PATH="${BASE_DIR}/${ARTIST_CLEAN}/${ALBUM_CLEAN}"
    mkdir -p "$RECORDING_PATH"

    # Temporaere Aufnahmedatei
    TEMP_RECORDING=$(mktemp --suffix=.wav)

    echo "Aufnahme startet für $ARTIST - $ALBUM"
    echo "Detektiere Trackwechsel bei Stille (2 Sekunden)"
    echo "Drücke Enter, um die Aufnahme manuell zu beenden"

    # Aufnahme starten
    arecord -D hw:${HW_ID},0 -f cd "$TEMP_RECORDING" &
    RECORD_PID=$!

    # Warte bis Aufnahme beendet wird
    read -p "Drücke Enter, wenn die Albumaufnahme fertig ist: "
    kill $RECORD_PID
    wait $RECORD_PID 2>/dev/null

    # Volle Laenge speichern falls silence detection nich funzelt und zum generellen abgleichen der Tracks

    sox "$TEMP_RECORDING" "$RECORDING_PATH/fullalbum.flac"

    # Tracks mit Sox splitten
    sox "$TEMP_RECORDING" "$RECORDING_PATH/album.flac" silence 1 2.0 -50dB 1 2.0 -50dB 2 2.0 -50db : newfile : restart

    # Dateien umbenennen und in FLAC konvertieren
    cd "$RECORDING_PATH"
    TRACK_NUMBER=1
    for file in album*.flac; do
        if [ -f "$file" ]; then
            TRACK_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            TRACK_NAME_CLEAN=$(echo "${TRACK_NAMES[$((TRACK_NUMBER-1))]}" | sed 's/ /_/g')
            flac "$file" --output-name=" - ${TRACK_NAME_CLEAN}.flac" --output-prefix="$TRACK_NUMBER"
            rm "$file"
            ((TRACK_NUMBER++))
        fi
    done

    rm "$TEMP_RECORDING"
    echo "Tracks in $RECORDING_PATH gespeichert."
}
# Start recording for later manual clipping
function start_recording_manual_clip {	
	# Ask for name of album artist and album itself
	read -p "Enter name of the album artist: " ARTIST
	ARTIST_CLEAN=$(echo "$ARTIST" | sed 's/[^a-zA-Z0-9äöüÄÖÜß ]/-/g')
	read -p "Enter name of the album: " ALBUM
    ALBUM_CLEAN=$(echo "$ALBUM" | sed 's/[^a-zA-Z0-9äöüÄÖÜß ]/-/g')

	# Create directory
	RECORDING_PATH="${BASE_DIR}/${ARTIST_CLEAN}/${ALBUM_CLEAN}"
	mkdir -p "$RECORDING_PATH"

	# Temprorary recording file
	TEMP_RECORDING=$(mktemp --suffix=.wav)

	echo "Recording started for $ARTIST - $ALBUM "


	# Start recording
	arecord -D hw:${HW_ID},0 -f cd "$TEMP_RECORDING" &
	RECORD_PID=$!

	# Wait until the recording has finished
	read -p "Press Enter to stop the recording: "
	kill $RECORD_PID
	wait $RECORD_PID 2>/dev/null

	# Save full recording just in case

	sox "$TEMP_RECORDING" "$RECORDING_PATH/fullalbum.flac"

	# Rename file and convert to FLAC
	cd "$RECORDING_PATH"
 	if [ ! -f "${ALBUM_CLEAN}.flac" ]; then
		flac "fullalbum.flac" --output-name="${ALBUM_CLEAN}.flac"
	else
		echo "Datei existiert schon, wird in ${ALBUM_CLEAN}_copy.flac umbenannt."
		flac "fullalbum.flac" --output-name="${ALBUM_CLEAN}_copy.flac"
	fi
    rm "$TEMP_RECORDING"
	#rm "fullalbum.flac"
    echo "Tracks in $RECORDING_PATH gespeichert."

}

# Optionen
function options {
	echo "Options: "
	echo "1. Change capturing device"
	echo "2. Change recording directory"
	echo "3. Back"
	case $CHOICE in
		1) set_capturing_device ;;
		2) set_recording_directory ;;
		3) menu ;;
		*) echo "Invalid Choice, please try again, this time with a number maybe? No pressure though, i can do this all day ¯\_(ツ)_/¯"
}

# Set directory for recordings (current if left blank on init)
function set_recording_directory {
    read -p "Where do you want your recordings to be saved? (Enter for current directory) " USER_DIR
    BASE_DIR="$USER_DIR:-$(pwd)"
}

# Set audio recording device
function set_capturing_device {
    echo  "This program needs to know which device it should capture from, hence the following command will list all of the available options: "
	arecord -l
	read -p "Type in the ID of the device you want to use for capturing: " HW_ID
}





# Main Menu

function mainmenu {

    echo "Vinyl Digitizatorizor Main Menu: "
    echo "1. Record a vinyl and attempt to auto-cut it?"
    echo "2. Record a vinyl and save whole file to manually cut it?"
    echo "3. Options"
    echo "4. Exit"
    read -p "Choose an option: " CHOICE

    case $CHOICE in
        1) start_recording_auto_clip ;;
        2) start_recording_manual_clip ;;
        3) options ;;
        4) exit 0 ;;
        *) echo "Invalid option, try again... or don't idgaf ¯\_(ツ)_/¯." ;;
    esac


}

# main
while true; do
	init_check
	mainmenu
done
