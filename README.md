# Script to digitize your vinyls

## Description
Upon starting the script, you will land in the main menu in which you can choose to start the recording.

# How it is used
You *must* find out which hardware device your input stream lands, so that you can give the arecord command the correct audio interface.
Once you start recording, you will be asked 3 questions; Name of the Artist, Name of the Album and amount of Tracks.
Then it will record to a temporary .wav file and it will stop once you press the Enter key.
After pressing the Enter key, the script will do 2 things:
* it will save a version of the whole recording as a .flac file, for the case that the silence detection doesnt work correctly (or the song has multiple very low passages)
* it will save a temporary flac file that gets sliced up with the sox command and some certain (configurable) parameters like silence duration etc
Lastly, it will rename the tracks according to the names of the album that you previously entered.

# How i use it
I ssh onto my Music Raspi with the Volumio-Distribution that is hooked to a USB vinyl recorder.

# What do i need that for?
I was looking for a way to remotely digitize my vinyls so that i dont have to tediously move files around and rename them manually.


# Potential Improvements
* set recording directory manually
* give option to read a .txt file line by line that contains the name of the songs 
