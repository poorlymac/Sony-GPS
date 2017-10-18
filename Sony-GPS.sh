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

function write_file {
	cd "$MP4GPS"
	if [ ${#PMP4[@]} -eq 1 ]
	then
		# if there is only 1 softlink
		echo Linking ${PMP4[@]} to $PGPS.MP4
		#echo "ln -s $PMP4 $PGPS.MP4"
		ln -s ../$PMP4 $PGPS.MP4
	else
		# More than one we need to losslessly join
		echo Writing ${PMP4[@]} to $PGPS.MP4
		I=0
		FILES=()
		for P4 in "${PMP4[@]}"
		do
			I=$((I+1))
			TS="/tmp/Sony-GPS${I}.ts"
			FILES+=($TS)
			# Convert to TransportStream
			"$FFMPEG" -y -i "../${P4}" -c copy -bsf:v h264_mp4toannexb -f mpegts $TS
		done
		# Join TrnasportStreams
		"$FFMPEG" -y -i "concat:$(IFS=\|; echo "${FILES[*]}")" -c copy -bsf:a aac_adtstoasc $PGPS.MP4
		# Cleanup
		rm -f /tmp/Sony-GPS*.ts
	fi
	ln -s ../PRIVATE/SONY/GPS/$PGPS.LOG .
	# Convert NMEA to GPX if we have GPSBabel and the LOG exists
	if [ "$GPSBABEL" != "" ] && [ -f "$PGPS.LOG" ]
	then
		"$GPSBABEL" -i nmea -f $PGPS.LOG  -o gpx,gpxver=1.1 -F $PGPS.gpx
	fi
	# Return back to directory
	cd -
}

MISSING=0
# Check for ffmpeg
FFMPEG="`which ffmpeg`"
if [ ! -f "$FFMPEG" ]
then
	echo "ERROR: ffmpeg missing, brew install ffmpeg"
	MISSING=1
fi
# Check for ffmpeg
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

# Check if we are in the correct directory
MP4GPS="MP4GPS"
if [ -d "MP_ROOT" ] && [ -d "PRIVATE/SONY/GPS" ]
then
	echo "Creating linked Videos (or joined) and GPS in $MP4GPS"
	mkdir -p "$MP4GPS"
else
	echo "Usage $0 from the Sony storage root, i.e. where MP_ROOT and PRIVATE are."
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

MP4S=(`ls MP_ROOT/*/*.MP4`)
MP4C=${#MP4S[@]}
echo "Found $MP4C MP4's"
F=0
PART=1
for MP4 in "${MP4S[@]}"
do
	F=$((F + 1))

	# Determine Start
	CD=`exiftool -CreateDate ${MP4} -d "%y%m%d:%H:%M:%S" 2>/dev/null`
	if [ $? -eq 0 ]
	then
		# Turn Start time into seconds
		DY=`echo ${CD} | sed 's/ //g' | awk -F\: '{print $2}'`
		HR=`echo ${CD} | sed 's/ //g' | awk -F\: '{print $3}'`
		MN=`echo ${CD} | sed 's/ //g' | awk -F\: '{print $4}'`
		SC=`echo ${CD} | sed 's/ //g' | awk -F\: '{print $5}'`
		START_SECONDS=$((10#$HR * 60 * 60 + 10#$MN * 60 + 10#$SC))

		# Check to see if this is a run on from the last file
		WRITE_PREVIOUS=0
		if [ "$DY" == "$PDY" ]
		then
			DF=$((START_SECONDS - PEND))
			# Check the gap between this and the next recording
			if [ $DF -le 3 ] && [ $DF -ge -3 ]
			then
				# The same recording if 3 seconds difference
				PART=$((PART + 1))
				LMP4=(${PMP4[@]})
				LMP4+=($MP4)
			else
				# A new recording
				LMP4=($MP4)
				WRITE_PREVIOUS=1
				PART=1
				G=$((G + 1))
			fi
		else
			# A new recording
			LMP4=($MP4)
			WRITE_PREVIOUS=1
			PART=1
			G=0
		fi

		# Write Previous
		if [ $WRITE_PREVIOUS -eq 1 ] && [ $F -ne 1 ]
		then
			write_file
		fi

		# Determine End
		DR=`exiftool -n -Duration "${MP4}" | sed 's/ //g'`
		SC=`echo ${DR} | awk -F[\:,\.] '{print $2}'`
		END_SECONDS=$((START_SECONDS + $SC))

		# Check for GPS
		GPS=`printf "${DY}%02X" $G`
		if [ -f "PRIVATE/SONY/GPS/$GPS.LOG" ]
		then
			echo ${MP4} ${CD} for ${DR} [$DY/$START_SECONDS to $END_SECONDS] part $PART GPS $GPS
		else
			echo ${MP4} ${CD} for ${DR} [$DY/$START_SECONDS to $END_SECONDS] part $PART GPS $GPS MISSING
		fi

		# Set next values
		PDY=$DY
		PEND=$END_SECONDS
		PGPS=$GPS
		PMP4=(${LMP4[@]})
	else
		echo $MP4 file invalid
	fi
done
write_file
