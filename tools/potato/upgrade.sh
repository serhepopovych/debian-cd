#!/bin/sh

# FOR POTATO
# Include upgrade* dir when available

set -e

for arch in i386 alpha sparc m68k
do
  if [ "$ARCH" = "$arch" -a -d "$MIRROR/dists/$CODENAME/main/upgrade-$ARCH" ];
  then
    cp -a $MIRROR/dists/$CODENAME/main/upgrade-$ARCH $TDIR/$CODENAME-$ARCH/1/
    mv $TDIR/$CODENAME-$ARCH/1/upgrade-$ARCH $TDIR/$CODENAME-$ARCH/1/upgrade
  fi
done

exit 0

