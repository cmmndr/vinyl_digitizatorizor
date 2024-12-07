# Script to digitize your vinyls

## Description
A short script to record digitize your vinyls via the arecord command on a linux system.
Upon starting the script, you will land in the main menu in which you can choose to start the recording.

## Requirements
A recording device that can capture the right amount of signal from a record player. So check if your record player has a built in amplifier, if not you need one otherwise the signal will be too weak.
This script is intended to be run on a linux machine that in turn listens to a hardware audio interface (most of the time a line in or a USB device). 
Almost any linux distribution will suffice.
Noteworthy commands used: sox, flac, arecord 
If you dont have them, get them via package manager.

# How it is used
You **must** find out which hardware device your input stream lands, so that you can give the arecord command the correct audio interface.
Once you start recording, you will be asked 3 questions; Name of the Artist, Name of the Album and amount of Tracks. Those are needed for the correct directory structure and also the correct amount of slicing for the individual tracks.
Then it will record to a temporary .wav file and it will stop once you press the Enter key.
After pressing the Enter key, the script will do 2 things:
* it will save a version of the whole recording as a .flac file, for the case that the silence detection doesnt work correctly (or the song has multiple very low passages)
* it will save a temporary flac file that gets sliced up with the sox command and some certain (configurable) parameters like silence duration etc
Lastly, it will rename the tracks according to the names of the album that you previously entered.

# How i use it
I ssh onto my Music Raspi with the Volumio-Distribution that is hooked to a USB vinyl recorder.

# What do i need that for?
I was looking for a way to remotely digitize my vinyls so that i dont have to tediously move files around and rename them manually.


