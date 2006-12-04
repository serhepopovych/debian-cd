#!/bin/sh -e

# Script to build one arch

if [ -z "$CF" ] ; then
    CF=CONF.sh
fi
. $CF

echo "Using defs from $CF" > /tmp/log

if [ -z "$COMPLETE" ] ; then
    export COMPLETE=1
fi

if [ -n "$1" ] ; then
    export ARCH=$1
fi

make distclean
make ${CODENAME}_status
if [ "$SKIPMIRRORCHECK" = "yes" ]; then
    echo " ... WARNING: skipping mirror check"
else
    echo " ... checking your mirror"
    RET=""
    make mirrorcheck-binary || RET=$?
    if [ -z "$RET" ] && [ -z "$NOSOURCE" ]; then
	make mirrorcheck-source || RET=$?
    fi
    if [ "$RET" ]; then
	echo "ERROR: Your mirror has a problem, please correct it." >&2
	exit 1
    fi
fi
echo " ... selecting packages to include"
if [ -e ${MIRROR}/dists/${DI_CODENAME}/main/disks-${ARCH}/current/. ] ; then
	disks=`du -sm ${MIRROR}/dists/${DI_CODENAME}/main/disks-${ARCH}/current/. | \
        	awk '{print $1}'`
else
	disks=0
fi
if [ -f $BASEDIR/tools/boot/$DI_CODENAME/boot-$ARCH.calc ]; then
    . $BASEDIR/tools/boot/$DI_CODENAME/boot-$ARCH.calc
fi
SIZE_ARGS=''
for CD in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
	size=`eval echo '$'"BOOT_SIZE_${CD}"`
	[ "$size" = "" ] && size=0
	[ $CD = "1" ] && size=$(($size + $disks))
	mult=`eval echo '$'"SIZE_MULT_${CD}"`
	[ "$mult" = "" ] && mult=100
    FULL_SIZE=`echo "($DEFBINSIZE - $size) * 1024 * 1024" | bc`
	echo "INFO: Reserving $size MB on CD $CD for boot files.  SIZELIMIT=$FULL_SIZE."
    if [ $mult != 100 ]; then
        echo "  INFO: Reserving "$((100-$mult))"% of the CD for extra metadata"
        FULL_SIZE=`echo "$FULL_SIZE * $mult" / 100 | bc`
        echo "  INFO: SIZELIMIT now $FULL_SIZE."
    fi
	SIZE_ARGS="$SIZE_ARGS SIZELIMIT${CD}=$FULL_SIZE"
done

FULL_SIZE=`echo "($DEFSRCSIZE - $size) * 1024 * 1024" | bc`

LISTTARGET="list"
if [ -n "$NOSOURCE" ] ; then
    LISTTARGET="bin-list"
fi
make $LISTTARGET $SIZE_ARGS SRCSIZELIMIT=$FULL_SIZE

# Setting IMAGETARGET directly is deprecated; NOSOURCE is preferred
if [ -z "$IMAGETARGET" ]; then
	if [ -n "$NOSOURCE" ] ; then
	    IMAGETARGET="bin-official_images"
	else
	    IMAGETARGET="official_images"
	fi
fi
echo " ... building the images; using target(s) \"$IMAGETARGET\""
make $IMAGETARGET

make imagesums
