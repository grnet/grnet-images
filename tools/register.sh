#!/bin/bash

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
. "$ROOTDIR/common.sh"

set -e

CONTAINER=images

usage() {
    local rc="$1"

    cat <<EOF

Usage: $0 [options] <diskdump> <cloud>

Upload and register a diskdump image with a cloud

OPTIONS:
    -h Print this message

    -d Do not delete other versions of this image fould on the cloud

    -k Ignore ssl

    -r Do not register the image

    -u Do not upload the image

    -y Assume Yes to all queries and do not prompt

EOF

    exit "$rc"
}

while getopts "hdkruy" opt; do
	case $opt in
		h) usage 0 ;;
		d) NO_DELETE="yes" ;;
		k) NO_SSL="yes" ;;
		r) NO_REGISTER="yes" ;;
		u) NO_UPLOAD="yes" ;;
		y) NO_PROMPT="yes" ;;
		?) error "Use \`-h' for help" ;;
	esac
done

shift $((OPTIND-1))

if [ $# -ne 2 ]; then
	error "usage: $0 <image> <cloud>"
fi

DISKDUMP="$1"
CLOUD="$2"

split_image_name "$DISKDUMP"

REGNAME="$DIRNAME/$NAME-$VERSION.regname"
if [ ! -f "$REGNAME" ]; then
	error "file: \`$REGNAME' missing"
fi

if [ "$NO_SSL" = yes ]; then
	ARGS="-k"
fi

# Upload
if [ "$NO_UPLOAD" != "yes" ]; then
	$KAMAKI $ARGS -c "$KAMAKIRC" file upload -f "$DISKDUMP" /images --cloud "$CLOUD"
	$KAMAKI $ARGS -c "$KAMAKIRC" file upload -f "$DISKDUMP".md5sum /images --cloud "$CLOUD"
fi


# Register
if [ "$NO_REGISTER" != "yes" ]; then
	$KAMAKI $ARGS -c "$KAMAKIRC" image register -f --name "$(cat "$REGNAME")" --location "/$CONTAINER/$BASENAME" --metafile "${DISKDUMP}.meta" --public --cloud "$CLOUD"
	$KAMAKI $ARGS -c "$KAMAKIRC" file modify --read-permission=* /$CONTAINER/${BASENAME}.md5sum --cloud "$CLOUD"
fi

images=$({ $KAMAKI -c "$KAMAKIRC" file list /$CONTAINER --cloud "$CLOUD" |
           awk '{ print $2 }' |
           grep ^"$NAME-$VERSION-"[0-9]\\+-x86_64\.diskdump\$ |
           grep -v ^"$NAME-$VERSION-$TAG"-x86_64\.diskdump\$; }  || true)

if [ "$NO_DELETE" != "yes" ]; then
	if [ "$NO_PROMPT" = "yes" ]; then
		yes="--yes"
	fi
	for image in $images; do
		echo "Deleting old image: $image"
		$KAMAKI $ARGS -c "$KAMAKIRC" file delete $yes /$CONTAINER/"$image" --cloud "$CLOUD"
		$KAMAKI $ARGS -c "$KAMAKIRC" file delete $yes /$CONTAINER/"$image".md5sum --cloud "$CLOUD"
		$KAMAKI $ARGS -c "$KAMAKIRC" file delete $yes /$CONTAINER/"$image".meta --cloud "$CLOUD"
	done
fi

