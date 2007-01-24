#
# This file will have to be sourced where needed
#

# Unset all optional variables first to start from a clean state
unset NONFREE           || true
unset CONTRIB           || true
unset EXTRANONFREE      || true
unset LOCAL             || true
unset LOCALDEBS         || true
unset SECURITY          || true
unset BOOTDIR           || true
unset SYMLINK           || true
unset COPYLINK          || true
unset MKISOFS           || true
unset MKISOFS_OPTS      || true
unset ISOLINUX          || true
unset EXCLUDE           || true
unset NORECOMMENDS      || true
unset NOSUGGESTS        || true
unset DOJIGDO           || true
unset JIGDOTEMPLATEURL  || true
unset JIGDOFALLBACKURLS || true
unset JIGDOINCLUDEURLS  || true
unset JIGDOSCRIPT       || true
unset JIGDO_OPTS        || true
unset PUBLISH_URL       || true
unset PUBLISH_PATH      || true
unset UDEB_INCLUDE      || true
unset UDEB_EXCLUDE      || true
unset BASE_INCLUDE      || true
unset BASE_EXCLUDE      || true
unset INSTALLER_CD      || true
unset MAXCDS            || true
unset SPLASHPNG         || true
unset OMIT_MANUAL	 || true
unset OMIT_RELEASE_NOTES || true

# The debian-cd dir
# Where I am (hoping I'm in the debian-cd dir)
export BASEDIR=`pwd`

# Building etch cd set ...
export CODENAME=etch

# By default use Debian installer packages from $CODENAME
if [ -z "$DI_CODENAME" ]; then
	export DI_CODENAME=$CODENAME
fi

# If set, controls where the d-i components are downloaded from.
# This may be an url, or "default", which will make it use the default url
# for the daily d-i builds. If not set, uses the official d-i images from
# the Debian mirror.
#export DI_WWW_HOME=default

# Version number, "2.2 r0", "2.2 r1" etc.
export DEBVERSION="4.0"

# Official or non-official set.
# NOTE: THE "OFFICIAL" DESIGNATION IS ONLY ALLOWED FOR IMAGES AVAILABLE
# ON THE OFFICIAL DEBIAN CD WEBSITE http://cdimage.debian.org
export OFFICIAL="Unofficial"
#export OFFICIAL="Official"
#export OFFICIAL="Official Beta"

# ... for arch
if [ -z "$ARCHES" ]; then
	CPU=`dpkg-architecture -qDEB_HOST_DPKG_CPU 2>/dev/null || true`
	if [ -z "$CPU" ]; then
		CPU=`dpkg-architecture -qDEB_HOST_ARCH`
	fi
	KERNEL=`dpkg-architecture -qDEB_HOST_DPKG_OS 2>/dev/null || true`
	if [ -z "$KERNEL" ]; then
		KERNEL=linux
	fi
	if [ $KERNEL = linux ] ; then
		ARCHES=$CPU
	else
		ARCHES="$KERNEL-$CPU"
	fi
	export ARCHES
fi

# IMPORTANT : The 4 following paths must be on the same partition/device.
#	      If they aren't then you must set COPYLINK below to 1. This
#	      takes a lot of extra room to create the sandbox for the ISO
#	      images, however. Also, if you are using an NFS partition for
#	      some part of this, you must use this option.
# Paths to the mirrors
export MIRROR=/mirror/debian

# Path of the temporary directory
export TDIR=/mirror/tmp

# Path where the images will be written
export OUT=/mirror/debian-cd-test

# Where we keep the temporary apt stuff.
# This cannot reside on an NFS mount.
export APTTMP=/mirror/tmp/apt

# Do I want to have NONFREE merged in the CD set
# export NONFREE=1

# Do I want to have CONTRIB merged in the CD set
export CONTRIB=1

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

# Where to find the security patches.  This directory should be the
# top directory of a security.debian.org mirror.
#export SECURITY="$TOPDIR"/debian/debian-security

# Sparc only : bootdir (location of cd.b and second.b)
# export BOOTDIR=/boot

# Symlink farmers should uncomment this line :
# export SYMLINK=1

# Use this to force copying the files instead of symlinking or hardlinking
# them. This is useful if your destination directories are on a different
# partition than your source files.
# export COPYLINK=1

# Options
# export MKISOFS=mkisofs
# export MKISOFS_OPTS="-r"		#For normal users
# export MKISOFS_OPTS="-r -F ."	#For symlink farmers

# ISOLinux support for multiboot on CD1 for i386
export ISOLINUX=1

# uncomment this to if you want to see more of what the Makefile is doing
#export VERBOSE_MAKE=1

# uncoment this to make build_all.sh try to build a simple CD image if
# the proper official CD run does not work
ATTEMPT_FALLBACK=yes

# Set your disk type here. Known types are:
# BC (businesscard): 650 MiB max (should be limited elsewhere,
#                    should never fill a CD anyway)
# NETINST:           650 MiB max (ditto)
# CD:                standard 74-min CD (650 MiB)
# CD700:             (semi-)standard 80-min CD (700 MiB)
# DVD:               standard 4.7 GB DVD
# CUSTOM:            up to you - specify a size to go with it (in 2K blocks)
export DISKTYPE=CD
#export DISKTYPE=CUSTOM
#export CUSTOMSIZE=XXXX

# We don't want certain packages to take up space on CD1...
#export EXCLUDE1="$BASEDIR"/tasks/exclude-$CODENAME
# ...but they are okay for other CDs (UNEXCLUDEx == may be included
# on CD x if not already covered)
#export UNEXCLUDE2="$BASEDIR"/tasks/unexclude-CD2-$CODENAME
# Any packages listed in EXCLUDE but not in any UNEXCLUDE will be
# excluded completely.

# Set this if the recommended packages should be skipped when adding 
# package on the CD.  The default is 'false'.
export NORECOMMENDS=1

# Set this if the suggested packages should be skipped when adding 
# package on the CD.  The default is 'true'.
#export NOSUGGESTS=1

# Produce jigdo files:
# 0/unset = Don't do jigdo at all, produce only the full iso image.
# 1 = Produce both the iso image and jigdo stuff.
# 2 = Produce only the jigdo stuff
export DOJIGDO=1

# HTTP/FTP URL for directory where you intend to make the templates
# available. You should not need to change this; the default value ""
# means "template in same dir as the .jigdo file", which is usually
# correct. If it is non-empty, it needs a trailing slash. "%ARCH%"
# will be substituted by the current architecture.
#export JIGDOTEMPLATEURL=""
#
# Name of a directory on disc to create data for a fallback server in. 
# Should later be made available by you at the URL given in
# JIGDOFALLBACKURLS. In the directory, two subdirs named "Debian" and
# "Non-US" will be created, and filled with hard links to the actual
# files in your FTP archive. Because of the hard links, the dir must
# be on the same partition as the FTP archive! If unset, no fallback
# data is created, which may cause problems - see README.
#export JIGDOFALLBACKPATH="$(OUT)/snapshot/"
#
# Space-separated list of label->URL mappings for "jigdo fallback
# server(s)" to add to .jigdo file. If unset, no fallback URL is
# added, which may cause problems - see README.
#export JIGDOFALLBACKURLS="Debian=http://myserver/snapshot/Debian/ Non-US=http://myserver/snapshot/Non-US/"
#
# Space-separated list of "include URLs" to add to the .jigdo file. 
# The included files are used to provide an up-to-date list of Debian
# mirrors to the jigdo _GUI_application_ (_jigdo-lite_ doesn't support
# "[Include ...]").
export JIGDOINCLUDEURLS="http://cdimage.debian.org/debian-cd/debian-servers.jigdo"
#
# $JIGDOTEMPLATEURL and $JIGDOINCLUDEURLS are passed to
# "tools/jigdo_header", which is used by default to generate the
# [Image] and [Servers] sections of the .jigdo file. You can provide
# your own script if you need the .jigdo file to contain different
# data.
#export JIGDOSCRIPT="myscript"

# A couple of things used only by publish_cds, so it can tweak the
# jigdo files, and knows where to put the results.
# You need to run publish_cds manually, it is not run by the Makefile.
export PUBLISH_URL="http://cdimage.debian.org/jigdo-area"
export PUBLISH_PATH="/home/jigdo-area/"

# Specify files and directories to *exclude* from jigdo processing. These
# files on each CD are expected to be different to those on the mirror, or
# are often subject to change. Any files matching entries in this list will
# simply be placed straight into the template file.
export JIGDO_EXCLUDE="'README*' /doc/ /md5sum.txt /.disk/ /pics/ 'Release*' 'Packages*' 'Sources*'"

# Specify files that MUST match entries in the externally-supplied
# md5-list. If they do not, the CD build process will fail; something
# must have been corrupted. Replaces the old mirrorcheck code.
export JIGDO_INCLUDE="/pool/"

# Specify the minimum file size to consider for jigdo processing. Any files
# smaller than this will simply be placed straight into the template file.
export JIGDO_OPTS="-jigdo-min-file-size 0"

for EXCL in $JIGDO_EXCLUDE; do
	JIGDO_OPTS="$JIGDO_OPTS -jigdo-exclude $EXCL"
done

for INCL in $JIGDO_INCLUDE; do
	JIGDO_OPTS="$JIGDO_OPTS -jigdo-force-md5 $INCL"
done

# File with list of packages to include when fetching modules for the
# first stage installer (debian-installer). One package per line.
# Lines starting with '#' are comments.  The package order is
# important, as the packages will be installed in the given order.
#export UDEB_INCLUDE="$BASEDIR"/data/$CODENAME/udeb_include

# File with list of packages to exclude as above.
#export UDEB_EXCLUDE="$BASEDIR"/data/$CODENAME/udeb_exclude

# File with list of packages to include when running debootstrap from
# the first stage installer (currently only supported in
# debian-installer). One package per line.  Lines starting with '#'
# are comments.  The package order is important, as the packages will
# be installed in the given order.
#export BASE_INCLUDE="$BASEDIR"/data/$CODENAME/base_include

# File with list of packages to exclude as above.
#export BASE_EXCLUDE="$BASEDIR"/data/$CODENAME/base_exclude

# Only put the installer onto the cd (set NORECOMMENDS,... as well,
# and also make sure you set TASK appropriately)
# INSTALLER_CD=0: nothing special (default)
# INSTALLER_CD=1: just add debian-installer (use TASK=tasks/debian-installer-$CODENAME)
# INSTALLER_CD=2: add d-i and base (use TASK=tasks/debian-installer+kernel-$CODENAME)
#export INSTALLER_CD=2
#export TASK=tasks/debian-installer+kernel-$CODENAME

# Parameters to pass to kernel (or d-i) when the CD boots. Not currently
# supported for all architectures.
#export KERNEL_PARAMS="DEBCONF_PRIORITY=critical"

# If set, limits the number of binary CDs to produce.
export MAXCDS=1

# If set, overrides the boot picture used.
#export SPLASHPNG="$BASEDIR/data/$CODENAME/splash-img.png"

# Set to 1 to save space by omitting the installation manual. 
# If so the README will link to the manual on the web site.
#export OMIT_MANUAL=1

# Set to 1 to save space by omitting the release notes
# If so we will link to them on the web site.
export OMIT_RELEASE_NOTES=1

# Set this to override the default location
#export RELEASE_NOTES_LOCATION="http://www.debian.org/releases/$CODENAME"

case "$OFFICIAL" in
    "Official")
	export OFFICIAL_VAL=2
	;;
    "Official Beta")
	export OFFICIAL_VAL=1
	;;
    *)
	export OFFICIAL_VAL=0
	;;
esac

##################################
# LOCAL HOOK DEFINITIONS
##################################
#
# Set these to point to scripts/programs to be called at various 
# points in the debian-cd image-making process. This is the ideal place
# to customise what's on the CDs, for example to add extra files or
# modify existing ones. Each will be called with the arguments in order:
#
# $TDIR (the temporary dir containing the build tree)
# $MIRROR (the location of the mirror)
# $DISKNUM (the image number in the set)
# $CDDIR (the root of the temp disc tree)
# $ARCHES (the set of architectures chosen)
#
# BE CAREFUL about what you do at each point: in the first couple of 
# cases, files and directories you're looking to use may not exist yet,
# you may need to worry about adding entries into md5sum.txt yourself
# and (in the last couple of cases) if you add any extra files you may
# end up over-filling the disc. If you *do* need to add files at the end
# of the process, see RESERVED_BLOCKS_HOOK below. It's strongly
# recommended to do this kind of customisation up-front if you can, it's
# much simpler that way!

# The disc_start hook. This will be called near the beginning of the
# start_new_disc script, just after the directory tree has been created
# but before any files have been added
#export DISC_START_HOOK=/bin/true

# The disc_pkg hook. This will be called just after the
# start_new_disc script has finished, just before make_disc_trees.pl
# starts to add package files.
#export DISC_PKG_HOOK=/bin/true

# The reserved_blocks hook; if set, this script should print the
# number of 2K blocks that need to be reserved for data to be added
# *after* a disc tree is filled with packages.
#export RESERVED_BLOCKS_HOOK=/bin/true

# The disc_finish hook. This will be called once a disc image is full,
# just after the last package rollback but before the last bits of
# cleanup are done on the temp disc tree
#export DISC_FINISH_HOOK=/bin/true

# The disc_end hook. This will be called *right* at the end of the
# image-making process in make_disc_trees.pl.
#export DISC_END_HOOK=/bin/true
