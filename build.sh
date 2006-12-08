#!/bin/sh -e

# Script to build one arch

if [ -z "$CF" ] ; then
    CF=CONF.sh
fi
. $CF

echo "Using CONF from $CF"

if [ -z "$COMPLETE" ] ; then
    export COMPLETE=1
fi

if [ -n "$@" ] ; then
    export ARCHES="$@"
fi

PATH=$BASEDIR/tools:$PATH
export PATH

if [ "$TASK"x = ""x ] ; then
	case "$INSTALLER_CD"x in
		"1"x)
			TASK=tasks/debian-installer-$CODENAME
			unset COMPLETE
			;;
		"2"x)
			TASK=tasks/debian-installer+kernel-$CODENAME
			unset COMPLETE
			;;
		*)
			COMPLETE=1
			;;
	esac
fi

export TASK COMPLETE

make distclean
make ${CODENAME}_status
if [ "$SKIPMIRRORCHECK" = "yes" ]; then
    echo " ... WARNING: skipping mirror check"
else
    echo " ... checking your mirror"
    RET=""
    make mirrorcheck || RET=$?
    if [ "$RET" ]; then
	echo "ERROR: Your mirror has a problem, please correct it." >&2
	exit 1
    fi
fi

if [ -z "$IMAGETARGET" ] ; then
    IMAGETARGET="official_images"
fi
echo " ... building the images; using target(s) \"$IMAGETARGET\""
make $IMAGETARGET

make imagesums
