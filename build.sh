#!/bin/sh

set -e

. CONF.sh
make distclean
make ${CODENAME}_status
make mirrorcheck
make list COMPLETE=1 SIZELIMIT1=$((525 * 1024 * 1024)) SRCSIZELIMIT=$((630 * 1024 * 1024))
make bin-official_images
