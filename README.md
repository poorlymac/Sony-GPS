# Sony-GPS
A bash script that prepares Sony HDRAS30V MP4 and GPS files for loading into other software

## What it does
* Creates a new directory MP4GPS
* Join and copies MP4's that are part of the same video to a new video (lossless)
* Aligns the MP4 filename with the GPS data filename
* If GPSBabel is installed, converts GPS from NMEA to more common GPX

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
