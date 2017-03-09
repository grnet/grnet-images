#!/bin/bash

. common.sh

set -e

FLAVOR_ID=4

usage() {
	local rc="$1"

	cat <<EOF
Usage: $0 <image_id> <cloud>

Create a VM for testing purposes

EOF
	exit "$rc"
}

while getopts "h" opt; do
	case $opt in
		h) usage 0;;
		?) error "Use \`-h' for help" ;;
	esac
done

shift $((OPTIND-1))

if [ $# -ne 2 ]; then
	error "usage: $0 <image_id> <cloud>"
fi

IMG_ID="$1"
CLOUD="$2"

kamaki -c kamakirc --cloud "$CLOUD" server create --name Test-$RANDOM --flavor-id $FLAVOR_ID --image-id "$IMG_ID"

