#! /bin/sh
set -e

## Wrapper script for build.sh
## See CONF.sh for the meaning of variables used here.

# Set configuration file to be used for the build and source it
export CF=CONF.sh
. $CF
export DEBIAN_CD_CONF_SOURCED=true

# The architecture for which to build the CD/DVD image
if [ "$2" ]; then
	ARCH=$2
else
	ARCH=i386
fi
export ARCH

# The suite the installed system will be based on
export CODENAME=lenny
# The suite the udebs for the installer will be taken from
export DI_CODENAME=lenny

## The debian-installer images to use (must be compatible with the suite
## (DI_CODENAME) from which udebs will be taken
## Use only one of the next three settings
## See also: tools/boot/<codename>/boot-$ARCH scripts
# Use official images
export DI_WWW_HOME=http://ftp.nl.debian.org/debian/dists/lenny/main/installer-$ARCH/current/images/
# Or, use daily built d-i images (most from http://people.debian.org)
#export DI_WWW_HOME=default
# Or, use custom (locally built) images
#export DI_DIR=$LOCALDEBS/images/$ARCH

# Include local packages in the build
#export LOCAL=1

# Build only the first CD/DVD by default
# Uncomment/change separate values for full/dvd targets further down
# if you want to build more
export MAXCDS=1

# Options that include CODENAME should be set here if needed, not in CONF.sh
#export EXCLUDE1="$BASEDIR"/tasks/exclude-$CODENAME
#export UNEXCLUDE2="$BASEDIR"/tasks/unexclude-CD2-$CODENAME
#export UDEB_INCLUDE="$BASEDIR"/data/$CODENAME/udeb_include
#export UDEB_EXCLUDE="$BASEDIR"/data/$CODENAME/udeb_exclude
#export BASE_INCLUDE="$BASEDIR"/data/$CODENAME/base_include
#export BASE_EXCLUDE="$BASEDIR"/data/$CODENAME/base_exclude
#export SPLASHPNG="$BASEDIR/data/$CODENAME/splash-img.png"
#export RELEASE_NOTES_LOCATION="http://www.debian.org/releases/$CODENAME"


## Except for the MAXCDS settings, the rest of the script should just work

# Set variables that determine the type of image to be built
export DISKTYPE="$1"
case $DISKTYPE in
    BC)
	export INSTALLER_CD=1
	;;
    NETINST)
	export INSTALLER_CD=2
	;;
    CD)
	unset INSTALLER_CD
	#export MAXCDS=3
	;;
    DVD)
	export INSTALLER_CD=3
	#export MAXCDS=1
	;;
    *)
	echo "Usage: build_arch.sh BC|NETINST|CD|DVD [<ARCH>]"
	exit 1
	;;
esac

if [ "$LOCAL" ]; then
	echo "Updating Packages files for local repository"
	./tools/Packages-gen.sh $CODENAME
	if [ "$DI_CODENAME" ] && [ "$DI_CODENAME" != "$CODENAME" ]; then
		./tools/Packages-gen.sh $DI_CODENAME
	fi
fi

# Update debian-installer task files
if [ -d tasks ]; then
	echo "Updating debian-installer task files..."
	(
		cd tasks
		../tools/generate_di_list
		../tools/generate_di+k_list
	)
else
	echo "Error: cannot find tasks directory"
	exit 1
fi

echo
echo "Starting the actual debian-cd build..."
./build.sh $ARCH

# Avoid conflicts when the repository is updated later
if [ -d .svn ]; then
	echo
	echo "Cleanup: reverting generated changes in tasks..."
	svn revert tasks/debian-installer-* \
		   tasks/debian-installer+kernel-*
fi
