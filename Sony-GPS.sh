#!/bin/bash
################################################################################
# PROGRAM : Sony-GPS
# BY      : Paul Schaap
# DATED   : 2017-10-14
# PURPOSE : To allow Sony Action Cam data to be used with other softwares
#           - join MP4's that are part of the same video
#           - align MP4 filename with GPS data filename
#           - Convert GPS from NMEA to more common GPX
################################################################################

MISSING=0
# Check for ffmpeg
FFMPEG="`which ffmpeg`"
if [ ! -f "$FFMPEG" ]
then
	echo "ERROR: ffmpeg missing, brew install ffmpeg"
	MISSING=1
fi
# Check for exiftool
EXIFTOOL="`which exiftool`"
if [ ! -f "$EXIFTOOL" ]
then
	echo "ERROR: exiftool missing, brew install exiftool"
	MISSING=1
fi
if [ $MISSING -eq 1 ]
then
	exit
fi

function find_log {
	GPS=""
	for LOG in $(ls $1/PRIVATE/SONY/GPS/*.LOG)
	do
		DATE=$(head -1 $LOG | awk -F\/ '{print $4}')
		if [ "$2" == "$DATE" ]
		then
			GPS=$LOG
		fi
	done
}

function transcode {
	TSC=${#TS[@]}
	if [ $TSC -gt 1 ]
	then
		rm -f MP4GPS/${NF}_$(basename $PRV_GPS | sed 's/\.[^.]*$//').mp4
		FILES=()
		for (( i=0; i<$TSC; i++ ))
		do
				FILENAME=${TS[$i]}
				echo "Transcoding $FILENAME ..."
				TSF="/tmp/Sony-GPS${i}.ts"
				FILES+=($TSF)
				"$FFMPEG" -y -hide_banner -loglevel panic -y -i "$FILENAME" -c copy -bsf:v h264_mp4toannexb -f mpegts $TSF
		done
		# Join TrnasportStreams
		"$FFMPEG" -hide_banner -loglevel panic -y -i "concat:$(IFS=\|; echo "${FILES[*]}")" -c copy -bsf:a aac_adtstoasc "${NF}_$(basename $PRV_GPS | sed 's/\.[^.]*$//').MP4"
		mv "${NF}_$(basename $PRV_GPS | sed 's/\.[^.]*$//').MP4" MP4GPS
		# Cleanup
		rm -f /tmp/Sony-GPS*.ts
	fi
}

# Check if we are in the correct directory
if [ "$(ls */MP_ROOT)" != "" ] && [ "$(ls */PRIVATE/SONY/GPS)" != "" ]
then
	mkdir -p MP4GPS
else
	echo "Usage $0 from one directory above the Sony storage roots, i.e. where there are MP_ROOT and PRIVATE subdirectories."
	exit
fi

# Look for GPSBabel
GPSBABEL=""
GPSBABELAPP="/Applications/GPSBabelFE.app/Contents/MacOS/gpsbabel"
GPSBABELCMD="`which gpsbabel`"
if [ -f "$GPSBABELCMD" ]
then
	GPSBABEL="$GPSBABELCMD"
	echo "GPSBabel found in ${GPSBABEL}, converting to GPX"
elif [ -f "$GPSBABELAPP" ]
then
	GPSBABEL="$GPSBABELAPP"
	echo "GPSBabel found in ${GPSBABEL}, converting to GPX"
else
	echo "GPSBabel not found, not converting to GPX"
fi

N=0
for MP4 in $(ls */MP_ROOT/*/*.MP4)
do
	CD=$("$EXIFTOOL" -CreateDate $MP4 | grep "^Create Date")
	Y4=${CD:34:4}
	Y2=${CD:36:2}
	MN=${CD:39:2}
	DY=${CD:42:2}
	HH=${CD:45:2}
	MM=${CD:48:2}
	SS=${CD:51:2}
	find_log "$(echo "$MP4" | awk -F "/" '{print $1}')" "$Y4$MN$DY$HH$MM$SS.000"
	if [ "$GPS" == "" ]
	then
		TS+=("$MP4")
		echo "$MP4 $PRV_GPS <- Continuation"
	else
		transcode
		if [ $(wc -l <"$GPS" | awk '{print $1}') -gt 10 ]
		then
			N=$((N+2))
			NF=$(printf "%03d" $N)
			TS=("$MP4")
			echo "Copying $MP4 and $GPS ..."
			rsync --progress $MP4 MP4GPS/${NF}_$(basename $GPS | sed 's/\.[^.]*$//').mp4
			cp $GPS MP4GPS/${NF}_$(basename $GPS | sed 's/\.[^.]*$//').nmea
			# Convert NMEA to GPX if we have GPSBabel and the LOG exists
			if [ "$GPSBABEL" != "" ]
			then
				"$GPSBABEL" -i nmea -f $GPS -o gpx,gpxver=1.1 -F MP4GPS/${NF}_$(basename $GPS | sed 's/\.[^.]*$//').gpx
			fi
			PRV_GPS=$GPS
		else
			echo "Ignoring $MP4 and $GPS ..."
		fi
	fi
done
transcode
