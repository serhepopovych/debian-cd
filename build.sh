#!/bin/sh

# Script to build one arch

. CONF.sh

[ -n "$1" ] && export ARCH=$1

make distclean
make ${CODENAME}_status
echo " ... checking your mirror"
make mirrorcheck
if [ $? -gt 0 ]; then
	echo "ERROR: Your mirror has a problem, please correct it." >&2
	exit 1
fi
echo " ... selecting packages to include"
disks=`du -sm ${MIRROR}/dists/${CODENAME}/main/disks-${ARCH}/current/. | \
        awk '{print $1}'`
if [ -f $BASEDIR/tools/boot/$CODENAME/boot-$ARCH.calc ]; then
    . $BASEDIR/tools/boot/$CODENAME/boot-$ARCH.calc
fi
SIZE_ARGS=''
for CD in 1 2 3 4; do
	size=`eval echo '$'"BOOT_SIZE_${CD}"`
	[ "$size" = "" ] && size=0
	[ $CD = "1" ] && size=$(($size + $disks))
	SIZE_ARGS="$SIZE_ARGS SIZELIMIT${CD}=$(((630 - $size) * 1024 *1024))"
done
make list COMPLETE=1 $SIZE_ARGS SRCSIZELIMIT=$((635 * 1024 * 1024))
echo " ... building the images"
make official_images

make imagesums
