#!/bin/bash

# Install files in /install and some in /doc

set -e

BDIR=$TDIR/$CODENAME-$ARCH

# Put the install documentation in /install
cd $BDIR/1/dists/$CODENAME/main/disks-$ARCH/current/documentation
mkdir $BDIR/1/install/documentation
cp *.{html,txt} $BDIR/1/install/documentation/
ln -sf install*.html $BDIR/1/install/index.html

# Put the boot-disk documentation in /doc too
mkdir $BDIR/1/doc/install
cd $BDIR/1/doc/install
for file in ../../install/documentation/*.{html,txt}
do
	ln -s $file
done

