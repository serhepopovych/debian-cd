#!/bin/sh

set -e

. CONF.sh
make distclean
make ${CODENAME}_status
make mirrorcheck
disks=`du -sm ${MIRROR}/dists/${CODENAME}/main/disks-${ARCH}/current/. | \
	awk '{print $1}'`
make list COMPLETE=1 SIZELIMIT1=$(((630 - ${disks}) * 1024 * 1024)) SRCSIZELIMIT=$((635 * 1024 * 1024))
make official_images
