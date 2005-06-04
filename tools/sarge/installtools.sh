#!/bin/bash
# Install files in /install and some in /doc

set -e

if [ "$RELEASE_NOTES_LOCATION"x = ""x ] ; then
	export RELEASE_NOTES_LOCATION="http://www.debian.org/releases/sarge"
fi

# The location of the tree for CD#1, passed in
DIR=$1

if [ "$OMIT_MANUAL" != 1 ]; then
	DOCDIR=doc

	if [ -n "$BOOTDISKS" -a -e $BOOTDISKS/current/$DOCDIR ] ; then
	        DOCS=$BOOTDISKS/current/$DOCDIR
	else
	        echo "WARNING: Using $DI_CODENAME bootdisk documentation"
	        DOCS=$MIRROR/dists/$DI_CODENAME/main/installer-$ARCH/current/$DOCDIR
	fi

	# Put the install documentation in /doc/install
	if [ ! -d $DOCS ]; then
	    echo "ERROR: Unable to copy installer documentation to CD."
	    exit
	fi
	cd $DOCS
	mkdir -p $DIR/$DOCDIR/install
	if ! cp -a * $DIR/$DOCDIR/install; then
	    echo "ERROR: Unable to copy installer documentation to CD."
	fi
fi

if [ "$OMIT_RELEASE_NOTES" != 1 ]; then
    RN=$DIR/doc/release-notes
    mkdir -p $RN
    cd $RN
    echo "Downloading most recent release notes for sarge"
    wget $RELEASE_NOTES_LOCATION/release-notes-$ARCH.tar.gz
    if [ -e release-notes-$ARCH.tar.gz ] ; then
        tar xzvf release-notes-$ARCH.tar.gz
        rm -f release-notes-$ARCH.tar.gz
        rm -f */*.ps
    else
        echo "No release notes found at $RELEASE_NOTES_LOCATION/release-notes-$ARCH.tar.gz"
    fi
fi
