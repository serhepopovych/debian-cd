# Common handy shell script functions

l=/var/run/reboot-lock

reboot_lock () {
    exec 3<$l
    if ! flock --shared -w 0 3; then
	echo 2>&1 "Cannot acquire reboot lock."
	#exit 1
    fi
}

reboot_unlock () {
    flock --shared -u 3
}

now () {
    date -u +%F:%H:%M:%S
}

build_description () {
    case $1 in
        NI)
	    DESC="Netinst CD";;
        MACNI)
	    DESC="Mac Netinst CD";;
        CD)
	    DESC="Full CD";;
        DVD)
            DESC="Full DVD";;
        BD)
            DESC="Blu-ray";;
        DLBD)
            DESC="Dual-layer Blu-ray";;
        KDECD)
	    DESC="KDE CD";;
        GNOMECD)
	    DESC="GNOME CD";;
        LIGHTCD)
	    DESC="XFCE/lxde CD";;
        XFCECD)
	    DESC="XFCE CD";;
        LXDECD)
	    DESC="lxde CD";;
	*)
	    DESC="UNKNOWN";;
    esac
    echo "$DESC"
}    

calc_time () {
    echo $1 $2 | awk '
    {
        split($1, start, ":")
        start_time = (3600*start[2]) + (60*start[3]) + start[4]
        split($2, end, ":")
        end_time = (3600*end[2]) + (60*end[3]) + end[4]
        # Cope with going to a new day; do not worry about more than 1 day!
        if (start[1] != end[1]) { end_time += 86400 }
        time_taken = end_time - start_time
        hours = int(time_taken / 3600)
        time_taken -= (hours * 3600)
        minutes = int(time_taken / 60)
        time_taken -= (minutes * 60)
        seconds = time_taken
        printf("%dh%2.2dm%2.2ds\n", hours, minutes, seconds)
    }'
}

build_started () {
    export BUILDNAME=$1
    BUILDS_RUNNING="$BUILDS_RUNNING $BUILDNAME"
    export ${BUILDNAME}START=`now`
}

build_finished () {
    ARCH="$1"
    BUILDNAME="$2"
    BUILDNAMESTART="${BUILDNAME}START"
    start=${!BUILDNAMESTART}

    . $PUBDIRJIG/$ARCH/$BUILDNAME-trace

    time_spent=`calc_time $start $end`
    echo "  $ARCH $BUILDNAME build started at $start, ended at $end (took $time_spent), error $error"
    if [ $error -ne 0 ] ; then
        arch_error="$arch_error "$BUILDNAME"FAIL/$error/$end/$logfile"
    fi
    case $BUILDNAME in
	*FIRMWARE*)
	    cp log/$logfile $PUBDIRJIG-firmware/$ARCH/$BUILDNAME.log
	    ;;
	*)
	    cp log/$logfile $PUBDIRJIG/$ARCH/$BUILDNAME.log
	    ;;
    esac
}

catch_parallel_builds () {
    # Catch parallel builds here                                                                                               
    while [ "$BUILDS_RUNNING"x != ""x  ] ; do
	BUILDS_STILL_RUNNING=""
	for BUILDNAME in $BUILDS_RUNNING; do
            if [ -e $PUBDIRJIG/$arch/$BUILDNAME-trace ] ; then
		build_finished $arch $BUILDNAME
            else
		BUILDS_STILL_RUNNING="$BUILDS_STILL_RUNNING $BUILDNAME"
            fi
	done
	BUILDS_RUNNING=$BUILDS_STILL_RUNNING
	if [ "$BUILDS_RUNNING"x != ""x  ] ; then
            sleep 1
	fi
    done
    if [ "$arch_error"x = ""x ] ; then
	arch_error="none"
    fi
    arch_end=`now`
    arch_time=`calc_time $arch_start $arch_end`
    echo "$arch build started at $arch_start, ended at $arch_end (took $arch_time), error(s) $arch_error"
}

# Slightly complicated setup
# iso-*   dirs have checksums for ISO files only
# bt-*    dirs have checksums for ISO and torrrent files only
# jigdo-* dirs have checksums for ISO and jigdo files only
#
# Uses the imagesums tool from debian-cd to grab pre-calculated ISO
# checksums from the jigdo files where possible, to save a lot of time
generate_checksums_for_arch () {
    ARCH=$1
    JIGDO_DIR=$2
    ISO_DIR=$(echo $JIGDO_DIR | sed 's,jigdo-,iso-,g')
    BT_DIR=$(echo $JIGDO_DIR | sed 's,jigdo-,bt-,g')

    # Do the torrents first, if they exist
    if [ -e $BT_DIR ]; then
	$TOPDIR/debian-cd/tools/imagesums $BT_DIR $EXTENSION > /dev/null
    fi

    # Now do the jigdos, if they exist
    if [ -e $JIGDO_DIR ]; then
	$TOPDIR/debian-cd/tools/imagesums $JIGDO_DIR $EXTENSION > /dev/null
	# And grep out the .iso checksums from there to the iso directory
	for file in $JIGDO_DIR/*SUMS*${EXTENSION}; do
	    out=$ISO_DIR/$(basename $file)
	    grep \\.iso $file > $out
	done
	if [ -e $BT_DIR ]; then
	    # Ditto for the bt directory
	    for file in $JIGDO_DIR/*SUMS*${EXTENSION}; do
		out=$BT_DIR/$(basename $file)
		grep \\.iso $file >> $out
	    done
	fi
    else
	# No jigdos, so do the ISOs by hand
	$TOPDIR/debian-cd/tools/imagesums $ISO_DIR $EXTENSION > /dev/null
	if [ -e $BT_DIR ]; then
	    for file in $ISO_DIR/*SUMS*${EXTENSION}; do
		out=$BT_DIR/$(basename $file)
		grep \\.iso $file >> $out
	    done
	fi
    fi
}

catch_live_builds () {
    # Catch parallel build types here

    if [ "$NOLIVE"x = ""x ] && [ "$NOOPENSTACK"x = ""x ] ; then
	return
    fi
    
    while [ ! -f $PUBDIRLIVETRACE ] || [ ! -f $PUBDIROSTRACE ] ; do
	sleep 1
    done

    . $PUBDIROSTRACE
    time_spent=`calc_time $start $end`
    echo "openstack build started at $start, ended at $end (took $time_spent), error $error"

    . $PUBDIRLIVETRACE
    time_spent=`calc_time $start $end`
    echo "live builds started at $start, ended at $end (took $time_spent), error $error"

}

arch_has_firmware () {
    arch=$1
    for arch1 in $ARCHES_FIRMWARE; do
        if [ "$arch" = "$arch1" ] ; then
	    return 0
	fi
    done
    return 1
}

get_archive_serial () {
    trace_file="$MIRROR/project/trace/ftp-master.debian.org"
    if [ -f "$trace_file" ]; then
        awk '/^Archive serial: / {print $3}' "$trace_file"
    else
        echo 'unknown'
    fi
}

rsync_to_pettersson () {
    LOCAL=$1
    REMOTE=$2
    OPTIONS="$3"
    rsync -az --delete $OPTIONS $LOCAL sync-to-pettersson:$REMOTE
}

publish_on_pettersson () {
    TARGETS="$@"
    echo "$TARGETS" | ssh publish-on-pettersson ./bin/receive_from_casulana
}

