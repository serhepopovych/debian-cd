#!/bin/bash

# Install files in /install and some in /doc

set -e

BDIR=$TDIR/$CODENAME-$ARCH

# Put the install documentation in /install
cd $BDIR/1/dists/$CODENAME/main/disks-$ARCH/current
cp *.{html,txt} $BDIR/1/install/
ln -sf install.en.html $BDIR/1/install/index.html

# Put the boot-disk documentation in /doc too
cd $BDIR/1/doc
for file in ../install/*.{html,txt}
do
	ln -s $file
done

