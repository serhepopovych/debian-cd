#!/bin/sh

set -e

. CONF.sh
make distclean
make ${CODENAME}_status
make mirrorcheck
make list COMPLETE=1 SIZELIMIT1=576716800
make official_images
