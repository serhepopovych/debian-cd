#!/bin/sh

set -e

. CONF.sh
make distclean
make ${CODENAME}_status
make mirrorcheck
make list COMPLETE=1 SIZELIMIT1=$((529 * 1024 * 1024)) SRCSIZELIMIT=$((635 * 1024 * 1024))
make official_images
