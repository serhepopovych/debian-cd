# Debian CD configuration file
# This file will have to be sourced where needed
#

# The YACS dir
export BASEDIR=/usr/share/debian-cd

# Building potato cd set ...
export CODENAME=potato

# ... for arch  
export ARCH=`dpkg --print-installation-architecture`

# Paths to the mirrors
export MIRROR=/home/ftp/debian
# Comment the following line if you don't have/want non-US
# export NONUS=/home/ftp/debian-non-US

# Path of the temporary directory
export TDIR=/home/ftp/tmp

# Path where the images will be written
export OUT=/home/ftp/debian-cd

# Do I want to have NONFREE
# export NONFREE=1

# Sparc only : bootdir (location of cd.b and second.b)
#export BOOTDIR=

# Symlink farmers should uncomment this line :
#export SYMLINK=1

# Options
#export MKISOFS=/usr/bin/mkhybrid
#export MKISOFS_OPTS="-a -r -T"      #For normal users
#export MKISOFS_OPTS="-a -r -F -T"   #For symlink farmers
