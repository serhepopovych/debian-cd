#!/bin/bash

# Install files in /install and some in /doc
set -e

# The location of the tree for CD#1, passed in
DIR=$1

DOCDIR=doc

if [ -n "$BOOTDISKS" -a -e $BOOTDISKS/current/$DOCDIR ] ; then
        DOCS=$BOOTDISKS/current/$DOCDIR
else
        echo "WARNING: Using woody bootdisk documentation"
        DOCS=$MIRROR/dists/woody/main/disks-$ARCH/current/$DOCDIR
fi


# Put the install documentation in /install
cd $DOCS
mkdir -p $DIR/install/$DOCDIR
if cp -a * $DIR/install/$DOCDIR/ ; then
    ln -f $DIR/install/$DOCDIR/install.en.html $DIR/install/$DOCDIR/index.html
else
    echo "ERROR: Unable to copy boot-floppies documentation to CD."
fi

# Put the boot-disk documentation in /doc too
mkdir -p $DIR/doc/install
cd $DIR/doc/install
for file in ../../install/$DOCDIR/*.{html,txt}
do
    ln $file
done

