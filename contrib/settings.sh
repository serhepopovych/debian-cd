export TRACE=/org/cdbuilder.debian.org/src/ftp/debian/project/trace/farbror.acc.umu.se
export ARCH_DI_DIR=/org/cdbuilder.debian.org/src/deb-cd/d-i/people.debian.org
export HOSTNAME=`hostname -f`

export PUBDIR=/org/cdbuilder.debian.org/dst/deb-cd

export MIRROR=/org/cdbuilder.debian.org/src/ftp/debian
export BASEDIR=/home/deb-cd/build/debian-cd
export MKISOFS=/home/deb-cd/build/mkisofs/usr/bin/mkisofs
if [ "$DATE"x = ""x ] ; then
    export DATE=`date -u +%Y%m%d`
fi
export PARALLEL=0
