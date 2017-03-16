#!/bin/bash

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
. "$ROOTDIR/common.sh"

HOST_PORT=11023
VNC_DISPLAY=1
CDROM=
DISK=

check_alive() {
	ps $1 &> /dev/null

	if [ $? -ne 0 ]; then
		error "VM died unexpectedly"
	fi
}

wait_on_pid() {
	echo -n "Waiting for VM to terminate ..."
	wait "$1"
	rc="$?"
	if [ $rc -ne 0 ]; then
		error "VM status: $rc"
	else
		success done
	fi
	exit "$rc"
}

usage() {
	local rc="$1"

	cat <<EOF
Usage: $0 [options] <device> [<username>]

Start a VM from a device

OPTIONS:
     -h Print this message

     -v Use this VNC display instaead of the default one [1]

     -p Use this host port to forward to VM's port 22 [11023]

     -c Attach this cdrom [""]

     -d Attach a second disk
EOF
	exit "$rc"
}

while getopts "hc:d:v:p:" opt; do
	case $opt in
		h) usage 0;;
		v) VNC_DISPLAY="$OPTARG"
			if ! [[ $VNC_DISPLAY =~ ^[0-9]+$ ]]; then
				error "VNC_DISPLAY not a number"
			fi
			;;
		p) HOST_PORT="$OPTARG"
			if ! [[ $HOST_PORT =~ ^[0-9]+$ || $HOST_PORT -lt 1024 ]]; then
				error "HOST_PORT not a valid port over 1024"
			fi
			;;
		c) CDROM="$(printf -- "-cdrom %q" "$OPTARG")"
			if [ ! -f "$OPTARG" ]; then
				error "CDROM not a valid file"
		  	fi
			;;
		d) DISK="$(printf -- "-drive file=%q,format=raw,cache=none,if=virtio" "$OPTARG")"
			if [ ! -e "$OPTARG" ]; then
				error "DISK not a valid file"
			fi
			;;
	esac
done

shift $((OPTIND-1))

if [ $# -lt 1 ]; then
	error "Device missing: usage: $0 <device> [<username>]"
fi

device="$1"

if grep -i windows <<< "$device" > /dev/null; then
	windows=yes
else
	windows=no
fi

if [ $windows = no -a $# -ne 2 ]; then
	error "Username missing for non-windows device: usage: $0 <device> <username>"
fi

user="$2"

HOSTFWD=""
if [ $windows = no ]; then
	HOSTFWD=",hostfwd=tcp::${HOST_PORT}-:22"
fi

echo -n "Starting VM in vnc display ${VNC_DISPLAY}... "
kvm -smp 1 -m 2048 -boot c -drive file="$device",format=raw,cache=none,if=virtio $DISK -netdev type=user,id=netdev0${HOSTFWD} -device virtio-net-pci,mac=aa:00:00:de:ad:de,netdev=netdev0 $CDROM -usbdevice tablet -vnc :$VNC_DISPLAY &
pid=$!
sleep 1
check_alive $pid
success done

if [ "$windows" = 'yes' ]; then
	wait_on_pid $pid
fi

echo -n "Waiting 5 seconds for the VM to boot ... "
sleep 5
success done

ssh-keygen -f /home/skalkoto/.ssh/known_hosts -R [localhost]:${HOST_PORT}

export SSHPASS=0ke@n0s
set 1 2 3 4 5
while [ 1 ]; do
	check_alive $pid

	echo -n "Testing VM connection ... "
	sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l $user localhost -p ${HOST_PORT} true
	connected=$?
	if [ $connected -eq 0 ]; then
		success done
		break
	fi

	test "$1" || { kill $pid; error "failed"; }
	echo -n "Retrying in $1 seconds... "
	sleep $1
	shift
done

while [ 1 ]; do
	sshpass -e ssh -l "$user" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null localhost -p ${HOST_PORT}
	while [ 1 ]; do
		echo -n "Reconnect with ssh [y/N]? "
		read answer
		answer=$(tr [A-Z] [a-z] <<< $answer)
		if [ "$answer" = "" ]; then
			answer="n"
		fi
		if [[  "$answer" =~ ^(y|n)$ ]]; then
			break
		fi
	done

	if [ "$answer" != y ]; then
		break
	fi
done

wait_on_pid $pid

