#
# This file will have to be sourced where needed
#

# The YACS dir
# Where I am (hoping I'm in the yacs dir)
export BASEDIR=`pwd`

# Building potato cd set ...
export CODENAME=potato

# ... for arch  
export ARCH=`dpkg --print-installation-architecture`

# IMPORTANT : The 4 following paths must be on the same partition/device.
#	      If they aren't then you must set COPYLINK below to 1. This
#	      takes a lot of extra room to create the sandbox for the ISO
#	      images, however. Also, if you are using an NFS partition for
#	      some part of this, you must use this option.
# Paths to the mirrors
export MIRROR=/ftp/debian

# Comment the following line if you don't have/want non-US
#export NONUS=/ftp/debian-non-US

# Path of the temporary directory
export TDIR=/ftp/tmp

# Path where the images will be written
export OUT=/rack/debian-cd

# Where we keep the temporary apt stuff.
# This cannot reside on an NFS mount.
export APTTMP=/ftp/tmp/apt

# Do I want to have NONFREE
# export NONFREE=1

# If you have a $MIRROR/dists/$CODENAME/local/binary-$ARCH dir with 
# local packages that you want to put on the CD set then
# uncomment the following line 
# export LOCAL=1

# Sparc only : bootdir (location of cd.b and second.b)
# export BOOTDIR=/boot

# Symlink farmers should uncomment this line :
# export SYMLINK=1

# Use this to force copying the files instead of symlinking or hardlinking
# them. This is useful if your destination directories are on a different
# partition than your source files.
# export COPYLINK=1

# Options
# export MKISOFS=/usr/bin/mkhybrid
export MKISOFS_OPTS="-a -r -T"		#For normal users
# export MKISOFS_OPTS="-a -r -F -T"	#For symlink farmers
