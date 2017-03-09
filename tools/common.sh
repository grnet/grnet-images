
red='\e[1;31m'
green='\e[1;32m'
rst='\e[0m'

error() { echo -e "${red}Error: $@${rst}"  >&2; exit 1; }
success() { echo -e "${green}$@${rst}" >&2; }

split_image_name() {
	BASENAME=$(basename "$1")
	DIRNAME=$(dirname "$1")

	if [[ "$BASENAME" =~ ^([0-9a-zA-Z_]*)-([0-9a-zA-Z_.~]*)-([0-9]*)-x86_64\.diskdump$ ]]; then
        	NAME="${BASH_REMATCH[1]}"
        	VERSION="${BASH_REMATCH[2]}"
        	TAG="${BASH_REMATCH[3]}"
	else
        	error "invalid image name"
	fi
}

: ${KAMAKI:="kamaki"}
