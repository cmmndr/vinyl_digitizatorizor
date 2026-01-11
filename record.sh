#!/bin/bash

# Abhängigkeiten prüfen
command -v sox >/dev/null 2>&1 || { 
    echo "sox wird benötigt. Installiere mit: sudo apt-get install sox"; 
    exit 1; 
}

# Verzeichnis für Aufnahmen
BASE_DIR="/home/volumio/recordings"
HW_ID=5

start_recording() {
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

    # Temporäre Aufnahmedatei
    TEMP_RECORDING=$(mktemp --suffix=.wav)

    echo "Aufnahme startet für $ARTIST - $ALBUM"
    echo "Detektiere Trackwechsel bei Stille (2 Sekunden)"
    echo "Drücke Enter, um die Aufnahme manuell zu beenden"

    # Aufnahme starten
    arecord -D hw:5,0 -f cd "$TEMP_RECORDING" &
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
start_vinyl() {
# Vinylaufnahme
	
	# Interpret, Album, Vinylnummer und Vinylseite abfragen
	read -p "Bitte gib den Interpreten ein: " ARTIST
	ARTIST_CLEAN=$(echo "$ARTIST" | sed 's/[^a-zA-Z0-9äöüÄÖÜß ]/-/g')
	read -p "Bitte gib den Albumnamen ein: " ALBUM
    	ALBUM_CLEAN=$(echo "$ALBUM" | sed 's/[^a-zA-Z0-9äöüÄÖÜß ]/-/g')
	#read -p "Bitte gib die Nummer der Vinyl ein: " VINYL_NUMBER
	
	#read -p "Bitte gib die Seite des Vinyls ein: " VINYL_SIDE

	# Verzeichnis erstellen
	RECORDING_PATH="${BASE_DIR}/${ARTIST_CLEAN}/${ALBUM_CLEAN}"
	mkdir -p "$RECORDING_PATH"

	# Temporäre Aufnahmedatei
	TEMP_RECORDING=$(mktemp --suffix=.wav)

	echo "Aufnahme startet für $ARTIST - $ALBUM "
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

	# Dateien umbenennen und in FLAC konvertieren
	cd "$RECORDING_PATH"
 	if [ ! -f "${ALBUM_CLEAN}.flac" ]; then
		flac "fullalbum.flac" --output-name="${ALBUM_CLEAN}.flac"
	else
		echo "Datei existiert schon, wird in ${ALBUM_CLEAN}_copy.flac umbenannt."
		flac "fullalbum.flac" --output-name="${ALBUM_CLEAN}_copy.flac"
	fi
    	rm "$TEMP_RECORDING"
	rm "fullalbum.flac"
    	echo "Tracks in $RECORDING_PATH gespeichert."

}

# Optionen
options(){
	
	echo "Um Aufnehmen zu koennen, muss der Befehl arecord das richtige Hardwaregeraet auswaehlen."
	arecord -l
	echo "Es muss aus dieser Liste ausgewaehlt werden um im Skript verwendet werden zu koennen."
	read -p "Welche Ziffer ist das richtige Aufnahmegeraet?" HW_ID
	
	



}




# Hauptmenü
while true; do
    echo "Audioaufnahme Menü:"
    echo "1. Audiodatei aufnehmen und schnippseln lassen?"
    echo "2. Audiodatei aufnehmen zum selbst schnippseln?"
    echo "3. Optionen"
    echo "4. Beenden"
    read -p "Wähle eine Option: " CHOICE

    case $CHOICE in
        1) start_recording ;;
	2) start_vinyl ;;
	3) options ;;
        4) exit 0 ;;
        *) echo "Ungültige Eingabe. Bitte erneut versuchen." ;;
    esac
done
