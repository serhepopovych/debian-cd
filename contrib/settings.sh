export HOSTNAME=`hostname -f`

export CODENAME=buster
export OUT_BASE=~/publish
export CD_I_F=${OUT_BASE}/unofficial/non-free/images-including-firmware
export TRACE=/srv/cdbuilder.debian.org/src/ftp/debian/project/trace/$(hostname).debian.org
export ARCH_DI_DIR=/srv/cdbuilder.debian.org/src/deb-cd/d-i
export PUBDIR=/srv/cdbuilder.debian.org/dst/deb-cd
export MIRROR=/srv/cdbuilder.debian.org/src/ftp/debian
export BASEDIR=~/build.${CODENAME}/debian-cd
export MKISOFS=~/build.${CODENAME}/mkisofs/usr/bin/mkisofs
export EXTRACTED_SOURCES=${OUT_BASE}/cd-sources/
export LIVE_OUT=${OUT_BASE}/.live

if [ "$DATE"x = ""x ] ; then
    export DATE=`date -u +%Y%m%d`
fi

if [ "$ARCHES"x = ""x ] ; then
    ARCHES="amd64 i386 multi-arch arm64 armhf armel source ppc64el mips mipsel mips64el s390x"
fi

if [ "$ARCHES_FIRMWARE"x = ""x ] ; then
    ARCHES_FIRMWARE="amd64 i386 multi-arch"
fi

