export TRACE=/org/cdbuilder.debian.org/src/ftp/debian/project/trace/pettersson.debian.org
export ARCH_DI_DIR=/org/cdbuilder.debian.org/src/deb-cd/d-i
export HOSTNAME=`hostname -f`

export PUBDIR=/org/cdbuilder.debian.org/dst/deb-cd

export MIRROR=/org/cdbuilder.debian.org/src/ftp/debian
export BASEDIR=~/build.wheezy/debian-cd
export MKISOFS=~/build.wheezy/mkisofs/usr/bin/mkisofs
if [ "$DATE"x = ""x ] ; then
    export DATE=`date -u +%Y%m%d`
fi

export EXTRACTED_SOURCES=/mnt/nfs-cdimage/cd-sources

if [ "$ARCHES"x = ""x ] ; then
    ARCHES="i386 source amd64 multi-arch powerpc armel armhf ia64 mips mipsel s390 s390x sparc kfreebsd-amd64 kfreebsd-i386"
fi

if [ "$ARCHES_FIRMWARE"x = ""x ] ; then
    ARCHES_FIRMWARE="amd64 i386 powerpc multi-arch"
#    ARCHES_FIRMWARE="amd64"
fi

