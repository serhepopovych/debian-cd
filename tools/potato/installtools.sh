#!/bin/bash

# Install files in /install and some in /doc

set -e

BDIR=$TDIR/$CODENAME-$ARCH

if [ "$ARCH" = "powerpc" ]; then
	DOCDIR="docs"
else
	DOCDIR="documentation"
fi

# Put the install documentation in /install
cd $BDIR/1/dists/$CODENAME/main/disks-$ARCH/current/$DOCDIR
mkdir $BDIR/1/install/$DOCDIR
cp *.{html,txt} $BDIR/1/install/$DOCDIR/
ln -sf install*.html $BDIR/1/install/index.html

# Put the boot-disk documentation in /doc too
mkdir $BDIR/1/doc/install
cd $BDIR/1/doc/install
for file in ../../install/$DOCDIR/*.{html,txt}
do
	ln -s $file
done

