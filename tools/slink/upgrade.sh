#!/bin/sh

# FOR SLINK
# Include the upgrade dir when available

if [ "$ARCH" = "i386" -a -d "$MIRROR/dists/$CODENAME/main/upgrade-older-$ARCH" \
     -a -d "$MIRROR/dists/$CODENAME/main/upgrade-2.0-$ARCH" ]; then

	$BASEDIR/tools/add_files $TDIR/$CODENAME-$ARCH/1 $MIRROR \
	  dists/$CODENAME/main/upgrade-older-$ARCH \
	  dists/$CODENAME/main/upgrade-2.0-$ARCH

elif [ "$ARCH" = "i386" ]; then
	echo "UPGRADE DIR FOR I386 ARE MISSING !!" >&2
	exit 1
fi

exit 0;
