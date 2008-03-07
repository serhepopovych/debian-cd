#! /bin/sh
set -e

if [ ! -d $LOCALDEBS ]; then
	echo "error: LOCALDEBS variable not set"
	exit 1
fi
cd $LOCALDEBS

distr=$1
if [ -z "$distr" ]; then
	echo "Usage: $(basename $0) <codename>"
	exit 1
elif [ ! -d dists/$distr/local/ ]; then
	echo "No local repository matching '$distr' was found"
	exit 1
fi

for repo in dists/$distr/local/binary-*; do
	[ -d $repo ] || break
	echo Creating Packages file for $repo...
	apt-ftparchive packages $repo | gzip >$repo/Packages.gz
done
for repo in dists/$distr/local/debian-installer/binary-*; do
	[ -d $repo ] || break
	echo Creating Packages file for $repo...
	apt-ftparchive packages $repo | gzip >$repo/Packages.gz
done
echo "Done."
