#
# This file will have to be sourced where needed
#

# The YACS dir
# Where I am (hoping I'm in the yacs dir)
export BASEDIR=`pwd`

# Building potato cd set ...
export CODENAME=potato

# ... for arch  
export ARCH=i386

# IMPORTANT : The 3 following paths must be on the same partition/device
#             or you won't be able to use debian-cd in the standard way.
#             If really you can't then, you can try with the symlink farm,
#             read the README for more information about this.
# Paths to the mirrors
export MIRROR=/ftp/debian
# Comment the following line if you don't have/want non-US
export NONUS=/ftp/debian-non-US
# Path of the temporary directory
export TDIR=/ftp/tmp

# Path where the images will be written
export OUT=/rack/debian-cd

# Do I want to have NONFREE
# export NONFREE=1

# If you have a $MIRROR/dists/$CODENAME/local/binary-$ARCH dir with 
# local packages that you want to put on the CD set then
# uncomment the following line 
#export LOCAL=1

# Sparc only : bootdir (location of cd.b and second.b)
#export BOOTDIR=

# Symlink farmers should uncomment this line :
#export SYMLINK=1

# Options
#export MKISOFS=/usr/bin/mkhybrid
#export MKISOFS_OPTS="-a -r -T"      #For normal users
#export MKISOFS_OPTS="-a -r -F -T"   #For symlink farmers
