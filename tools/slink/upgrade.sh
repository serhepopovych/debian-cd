#!/bin/sh

# FOR SLINK
# Include the upgrade dir when available

if [ "$ARCH" = "i386" -a -d "$MIRROR/dists/$CODENAME/main/upgrade-older-$ARCH" \
     -a -d "$MIRROR/dists/$CODENAME/main/upgrade-2.0-$ARCH" ]; then
   for dir in $TDIR/$CODENAME-$ARCH/CD1*
   do
	$BASEDIR/tools/add_files $dir $MIRROR \
	  dists/$CODENAME/main/upgrade-older-$ARCH \
	  dists/$CODENAME/main/upgrade-2.0-$ARCH
   done
elif [ "$ARCH" = "i386" ]; then
	echo "UPGRADE DIR FOR I386 ARE MISSING !!" >&2
	exit 1
fi

exit 0;
