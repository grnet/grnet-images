#!/bin/bash

. common.sh

set -e

if [ $# -ne 2 ]; then
	error "usage: $0 <image> <cloud>"
fi

DISKDUMP="$1"
CLOUD="$2"

split_image_name "$DISKDUMP"

DISKDUMP_URL=$($KAMAKI -c kamakirc --cloud "$CLOUD" file publish "/images/$DISKDUMP")
META_URL=$($KAMAKI -c kamakirc --cloud "$CLOUD" file publish "/images/$DISKDUMP.meta")
MD5SUM_URL=$($KAMAKI -c kamakirc --cloud "$CLOUD" file publish "/images/$DISKDUMP.md5sum")

echo "$NAME-$VERSION-x86_64.diskdump $DISKDUMP_URL"
echo "$NAME-$VERSION-x86_64.diskdump.meta $META_URL"
echo "$NAME-$VERSION-x86_64.diskdump.md5sum $MD5SUM_URL"

