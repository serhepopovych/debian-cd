# The debian-cd dir
export BASEDIR=/usr/share/debian-cd

# Building woody cd set ...
export CODENAME=woody

# Version number, "2.2 r0", "2.2 r1" etc.
export DEBVERSION="3.0 prerelease"

# Official or non-official set.
# NOTE: THE "OFFICIAL" DESIGNATION IS ONLY ALLOWED FOR IMAGES AVAILABLE
# ON THE OFFICIAL DEBIAN CD WEBSITE http://cdimage.debian.org
export OFFICIAL="Unofficial"
#export OFFICIAL="Official"
#export OFFICIAL="Official Beta"

# ... for arch  
export ARCH=`dpkg --print-installation-architecture`

# IMPORTANT : The 4 following paths must be on the same partition/device.
#	      If they aren't then you must set COPYLINK below to 1. This
#	      takes a lot of extra room to create the sandbox for the ISO
#	      images, however. Also, if you are using an NFS partition for
#	      some part of this, you must use this option.
# Paths to the mirrors
export MIRROR=/home/ftp/debian

# Comment the following line if you don't have/want non-US
#export NONUS=/ftp/debian-non-US

# And this option will make you 2 copies of CD1 - one with all the
# non-US packages on it, one with none. Useful if you're likely to
# need both.
#export FORCENONUSONCD1=1

# Path of the temporary directory
export TDIR=/home/ftp/tmp

# Path where the images will be written
export OUT=/home/ftp/debian-cd

# Where we keep the temporary apt stuff.
# This cannot reside on an NFS mount.
export APTTMP=/home/ftp/tmp/apt

# Do I want to have NONFREE merged in the CD set
# export NONFREE=1

# Do I want to have NONFREE on a separate CD (the last CD of the CD set)
# WARNING: Don't use NONFREE and EXTRANONFREE at the same time !
# export EXTRANONFREE=1

# If you have a $MIRROR/dists/$CODENAME/local/binary-$ARCH dir with 
# local packages that you want to put on the CD set then
# uncomment the following line 
# export LOCAL=1

# If your local packages are not under $MIRROR, but somewhere else, 
# you can uncomment this line and edit to to point to a directory
# containing dists/$CODENAME/local/binary-$ARCH
# export LOCALDEBS=/home/joey/debian/va/debian

# If you want a <codename>-secured tree with a copy of the signed
# Release.gpg and files listed by this Release file, then
# uncomment this line
# export SECURED=1

# Sparc only : bootdir (location of cd.b and second.b)
# export BOOTDIR=/boot

# Symlink farmers should uncomment this line :
# export SYMLINK=1

# Use this to force copying the files instead of symlinking or hardlinking
# them. This is useful if your destination directories are on a different
# partition than your source files.
# export COPYLINK=1

# Options
# export MKISOFS=/usr/bin/mkisofs
# export MKISOFS_OPTS="-r -T"		#For normal users
# export MKISOFS_OPTS="-r -F . -T"	#For symlink farmers

# uncomment this to if you want to see more of what the Makefile is doing
#export VERBOSE_MAKE=1

# uncoment this to make build_all.sh try to build a simple CD image if
# the proper official CD run does not work
#ATTEMPT_FALLBACK=yes

# We don't want certain packages to take up space on CD1...
#export EXCLUDE="$BASEDIR"/tasks/exclude-potato
# ...but they are okay for other CDs (UNEXCLUDEx == may be included on CD >= x)
#export UNEXCLUDE2="$BASEDIR"/tasks/unexclude-CD2-potato
# Any packages listed in EXCLUDE but not in any UNEXCLUDE will be
# excluded completely.

# We also exclude some source packages
#export SRCEXCLUDE="$BASEDIR"/tasks/exclude-src-potato
