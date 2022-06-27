#!/bin/bash
set -e

if [[ $1 != "unshared" ]]; then
    echo "Unsharing mount namespace"
    unshare -m ${BASH_SOURCE[0]} unshared
    exit
fi


ROOT="yalcut"

# Designate chroot dir as mountpoint and disable nosuid and nodev under it
mount --bind $ROOT $ROOT
mount -o remount,suid,dev $(realpath $ROOT)


export PATH=/bin:/usr/bin:/sbin
export LD_PRELOAD=
export LD_LIBRARY_PATH=

# Complete debootstrap process
chroot $ROOT /debootstrap/debootstrap --second-stage


# Mount actual dev and proc into chroot
mount --bind /dev $ROOT/dev
mount --bind /dev/pts $ROOT/dev/pts
mount --bind /dev/cpuset $ROOT/dev/cpuset
mount --bind /proc $ROOT/proc
mount --bind /sys $ROOT/sys

# Fix DNS
echo "nameserver 1.1.1.1" > $ROOT/etc/resolv.conf


PACKAGES="git tmux vim build-essential python3 htop openssh-server"

chroot $ROOT /bin/sudo -i apt update
chroot $ROOT /bin/sudo -i apt install $PACKAGES


