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

## GPS overlays using Garmin VIRB Edit
What I then do with my videos is use [Garmin VIRB Edit](https://itunes.apple.com/au/app/garmin-virb-edit/id703910885?mt=12) to add in my GPS. Actions:
1. "Create Video"
2. "Map"
3. "Import G-Metrix..."
4. "On My Computer"
5. Choose your GPX file
6. "Use this Log"
7. "Map" -> "Terrain"
8. Screenshot the terrain Command+Shift+4, I do 615x615
9. Run Screenshot through [ImageMagick](https://www.imagemagick.org/script/index.php) to make it transparent (60%) e.g. ```convert 17091803.png -alpha set -channel A -evaluate set 60% 17091803_Transparent.png```
10. "G-Metrix"
11. Choose Template
12. Delete any non required Gauges
13. "Gauges"
14. "Select a Data Type" -> "Logo"
15. "Clone and Edit Gauge (Beta) ..."
16. "Source: Choose" and choose the Transparent image, "Save" "Close"
17. Lay the Transparent Gauge on the video (current bug in VIRB 5.2.1 I go export then go back and it often dissappears, so I just redo)
18. Switch to Track gauge and lay the track over the Transparent Gauge
19. "Appearance" -> "Transform" and scale the track so that it lines up with the transparent GPS track, I find I have to switch to full screen mode to move it around with the arrow keys
20. Export !!!!

## Example Result from Garmin VIRB Edit
![VIRB Edit Rocks](VIRB%20Edit.png)
