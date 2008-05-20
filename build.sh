#!/bin/sh -e

# Script to build images for one or more architectures and/or source

if [ -z "$CF" ] ; then
    CF=CONF.sh
fi
. $CF

echo "Using CONF from $CF"

if [ -z "$COMPLETE" ] ; then
    export COMPLETE=1
fi

if [ $# -gt 1 ] ; then
    echo "ERROR: too many arguments." >&2
    exit 1
elif [ -n "$1" ] ; then
    export ARCHES="$1"
fi

PATH=$BASEDIR/tools:$PATH
export PATH

if [ "$TASK"x = ""x ] ; then
	case "$INSTALLER_CD"x in
		"1"x)
			TASK=tasks/debian-installer-$DI_CODENAME
			unset COMPLETE
			;;
		"2"x)
			TASK=tasks/debian-installer+kernel-$DI_CODENAME
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
echo " ... checking your mirror"
RET=""
make mirrorcheck || RET=$?
if [ "$RET" ]; then
	echo "ERROR: Your mirror has a problem, please correct it." >&2
	exit 1
fi

if [ -z "$IMAGETARGET" ] ; then
    IMAGETARGET="official_images"
fi
echo " ... building the images; using target(s) \"$IMAGETARGET\""
make $IMAGETARGET

make imagesums
