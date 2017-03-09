#!/bin/bash
set -e

. common.sh

if [ $# -ne 2 ]; then
	error "usage: $0 <image> <cloud>"
fi

CLOUD="$2"

$KAMAKI -c kamakirc file delete /images/"$1" --cloud "$CLOUD"
$KAMAKI -c kamakirc file delete /images/"$1".md5sum --cloud "$CLOUD"
$KAMAKI -c kamakirc file delete /images/"$1".meta --cloud "$CLOUD"


