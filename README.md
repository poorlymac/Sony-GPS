# Sony-GPS
A bash script that prepares Sony HDRAS30V MP4 and GPS files for loading into other software

## What it does
Creates a new directory MP4GPS and then does the following in this directory:
* Joins and copies MP4's that are part of the same video to a new video (lossless), softlinks videos that are standalone
* Aligns the MP4 filename with the GPS data filename
* Soflinks the GPS file
* If GPSBabel is installed, converts GPS from NMEA to more common GPX
__WARNING:__ The joining task has to create a new composite MP4 so uses more disk, therefore make sure you have sufficient disk

## Requires
* [ffmpeg](https://ffmpeg.org)
* [exiftool](https://www.sno.phy.queensu.ca/~phil/exiftool/)
* [GPSBabel](https://www.gpsbabel.org) (Optional)

## Running
```bash
cd /Volumes/Untitled
ls
MP_ROOT
PRIVATE
Sony-GPS.sh
```
