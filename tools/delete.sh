#!/bin/bash
set -e

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
. "$ROOTDIR/common.sh"

if [ $# -ne 2 ]; then
	error "usage: $0 <image> <cloud>"
fi

CLOUD="$2"

$KAMAKI -c "$KAMAKIRC" file delete /images/"$1" --cloud "$CLOUD"
$KAMAKI -c "$KAMAKIRC" file delete /images/"$1".md5sum --cloud "$CLOUD"
$KAMAKI -c "$KAMAKIRC" file delete /images/"$1".meta --cloud "$CLOUD"


