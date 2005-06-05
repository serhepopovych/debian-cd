#!/bin/sh

echo "Copying the upgrade bits for hppa"
cp -a $MIRROR/dists/sarge/main/upgrade-kernel $1/CD1/upgrade-kernel

exit 0
