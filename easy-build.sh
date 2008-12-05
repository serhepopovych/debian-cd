#! /bin/sh
set -e

## Wrapper script for build.sh
## See README.easy-build for instructions how to use this script.
## See also CONF.sh for the meaning of variables used here.

show_usage() {
	echo "Usage: $(basename $0) [-d kde|lxde|xfce|light] BC|NETINST|CD|DVD [<ARCH> ...]"
}


# Set configuration file to be used for the build and source it
export CF=CONF.sh
. $CF
export DEBIAN_CD_CONF_SOURCED=true
unset UPDATE_LOCAL


## Parse the parameters passed to the script

if [ $# -eq 0 ]; then
	show_usage
	exit 1
fi

desktop=
if [ "$1" = "-d" ]; then
	case $2 in
	    gnome)
		# Ignore (gnome is default)
		shift 2
		;;
	    kde|lxde|xfce|light)
		desktop=$2
		shift 2
		;;
	    *)
		show_usage
		exit 1
		;;
	esac
fi

export DISKTYPE="$1"
shift

# The architecture(s) for which to build the CD/DVD image
if [ "$1" ]; then
	ARCHES="$@"
else
	ARCHES=i386
fi


## For what release to build images

# The suite the installed system will be based on
export CODENAME=lenny
# The suite from which the udebs for the installer will be taken (normally
# the same as CODENAME)
export DI_CODENAME=lenny


## The debian-installer images to use. This must match the suite (DI_CODENAME)
## from which udebs will be taken.
## Use *only one* of the next four settings. The "%ARCH%" placeholder in the
## 2nd and 4th options will be magically expanded at runtime.
## See also: tools/boot/<codename>/boot-$ARCH scripts.

# Use official images from the local mirror
export DI_DIST=$DI_CODENAME
# or, use official images from an outside mirror
#export DI_WWW_HOME="http://ftp.nl.debian.org/debian/dists/$DI_CODENAME/main/installer-%ARCH%/current/images/"
# or, use daily built d-i images (most from http://people.debian.org)
#export DI_WWW_HOME=default
# or, use custom / locally built images
#export DI_DIR="$HOME/d-i_images/%ARCH%"


## Other options

# Include local packages in the build
#export LOCAL=1
# Automatically update the Packages file(s) for the "local" repository?
#UPDATE_LOCAL=1

# Number of CD/DVDs to build; comment out to build full set
MAX_CDS=1
MAX_DVDS=1

# Only create the ISO files; don't create jigdo files
#export MAXISOS=0
export MAXJIGDOS=0


## Options that include CODENAME should be set here if needed, not in CONF.sh

# Include proposed-updates
#export PROPOSED_UPDATES=$CODENAME-proposed-updates

#export UDEB_INCLUDE="$BASEDIR"/data/$CODENAME/udeb_include
#export UDEB_EXCLUDE="$BASEDIR"/data/$CODENAME/udeb_exclude
#export BASE_INCLUDE="$BASEDIR"/data/$CODENAME/base_include
#export BASE_EXCLUDE="$BASEDIR"/data/$CODENAME/base_exclude
#export SPLASHPNG="$BASEDIR/data/$CODENAME/splash-img.png"
#export RELEASE_NOTES_LOCATION="http://www.debian.org/releases/$CODENAME"


## The rest of the script should just work without any changes

# Set variables that determine the type of image to be built
case $DISKTYPE in
    BC)
	export INSTALLER_CD=1
	;;
    NETINST)
	export INSTALLER_CD=2
	;;
    CD)
	unset INSTALLER_CD
	[ -z "$MAX_CDS" ] || export MAXCDS=$MAX_CDS
	;;
    DVD)
	export INSTALLER_CD=3
	[ -z "$MAX_DVDS" ] || export MAXCDS=$MAX_DVDS
	;;
    *)
	show_usage
	exit 1
	;;
esac

# By default a GNOME CD/DVD is built, but KDE and Xfce are supported too
if [ "$desktop" ] && ([ $DISKTYPE = CD ] || [ $DISKTYPE = DVD ]); then
	TASK=Debian-$desktop
	if [ "$CODENAME" = etch ]; then
		KERNEL_PARAMS="tasks=\"$desktop-desktop, standard\""
	else
		KERNEL_PARAMS="desktop=$desktop"
	fi
	DESKTOP=$desktop
	export TASK KERNEL_PARAMS DESKTOP
fi

if [ "$LOCAL" ] && [ "$UPDATE_LOCAL" ]; then
	echo "Updating Packages files for local repository..."
	for arch in $ARCHES; do
		./tools/Packages-gen.sh $CODENAME $arch
		./tools/Packages-gen.sh -i $DI_CODENAME $arch
	done
	echo
fi

echo "Starting the actual debian-cd build..."
./build.sh "$ARCHES"
