#!/bin/bash

# Install files in /install and some in /doc
# 26-dec-99 changes for i386 (2.2.x) bootdisks --jwest
# 11-mar-00 added sparc to boot-disk documentation test  --jwest

set -e

BDIR=$TDIR/$CODENAME-$ARCH

# boot-disk location for documentation is inconsistant --jwest
if [ "$ARCH" = "powerpc" ]; then
	DOCDIR="docs"
 elif [ "$ARCH" = "i386" ]; then 
         DOCDIR="doc"
 elif [ "$ARCH" = "sparc" ]; then
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

# now make sure that the /doc directory is NOT on cd 2,3,4.etc
       rm -r $BDIR/2/doc        #remove doc dir on cd 2 
       rm -r $BDIR/3/doc        #remove doc dir on cd 3 
       rm -r $BDIR/4/doc        #remove doc dir on cd 4 

