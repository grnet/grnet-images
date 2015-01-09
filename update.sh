#!/bin/bash
set -e

if [ $# -ne 1 ]; then
	echo "Usage: $0 <changelog>" >&2
	exit 1
fi

changelog="$1"
distro=${changelog#Changelog.}
distro=( ${distro//_/ } )
for i in $(seq 0 $((${#distro[*]}-1))); do
	distro[$i]=${distro[$i]^}
done
distro=${distro[*]}
distro=${distro//-/ }

if [ ! -f "$changelog" ]; then
	echo "File $changelog does not exist!"
	exit 1
fi

old=$(md5sum "$changelog" | awk '{ print $1 }')
dch -c "$changelog" --force-distribution -D diskdump -U
new=$(md5sum "$changelog" | awk '{ print $1 }')

if [ "$old" != "$new" ]; then
	git reset HEAD
	git add "$changelog"
	git commit -e -m "Update ChangeLog for $distro"
fi
