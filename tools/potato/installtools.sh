#!/bin/bash

# Install files in /install and some in /doc
# 26-dec-99 changes for i386 (2.2.x) bootdisks --jwest

set -e

BDIR=$TDIR/$CODENAME-$ARCH

if [ "$ARCH" = "powerpc" ]; then
	DOCDIR="docs"
 elif [ "$ARCH" = "i386" ] ; then
         DOCDIR="doc"
else
	DOCDIR="documentation"
fi

# Put the install documentation in /install
cd $BDIR/1/dists/$CODENAME/main/disks-$ARCH/current/$DOCDIR
mkdir $BDIR/1/install/$DOCDIR
cp *.{html,txt} $BDIR/1/install/$DOCDIR/
ln -sf install*.html $BDIR/1/install/$DOCDIR/index.html

# Put the boot-disk documentation in /doc too
mkdir $BDIR/1/doc/install
cd $BDIR/1/doc/install
for file in ../../install/$DOCDIR/*.{html,txt}
do
	ln -s $file
done

