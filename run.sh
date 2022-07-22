#!/bin/bash
set -e

if [[ $1 != "unshared" ]]; then
    echo "Unsharing mount namespace"
    unshare -m ${BASH_SOURCE[0]} unshared
    exit
fi


ROOT="yalcut"

if [ ! -d "/dev/freezer/" ]; then
    echo "Mounting freezer subsystem"
    mkdir -p /dev/freezer/
    mount -t cgroup -ofreezer freezer /dev/freezer/
fi

mkdir -p /dev/freezer/$ROOT


# Upon exit, kill all tasks under cgroup
function cleanup()
{
    trap - SIGINT SIGHUP SIGTERM EXIT

    echo $$ > /dev/freezer/tasks
    echo "FROZEN" > /dev/freezer/$ROOT/freezer.state

    TASKS=$(cat /dev/freezer/$ROOT/tasks | sort -u)
    [[ ! -z "$TASKS" ]] && ( kill $TASKS ; echo "Killed $ROOT cgroup" )

    echo "THAWED" > /dev/freezer/$ROOT/freezer.state
}
trap "cleanup" SIGINT SIGHUP SIGTERM EXIT


# Use magisk to set selinux policy. Allow external app to connect to our unix domain socks
magiskpolicy --live 'allow untrusted_app_27 magisk unix_stream_socket {connectto read write setopt}'


# Designate chroot dir as mountpoint and disable nosuid and nodev under it
mount --bind $ROOT $ROOT
mount -o remount,suid,dev $(realpath $ROOT)

mkdir -p $ROOT/data
mkdir -p $ROOT/system
mkdir -p $ROOT/sdcard

# Mount dev, proc and android main directories into chroot
mount --bind /dev $ROOT/dev
mount --bind /dev/pts $ROOT/dev/pts
mount --bind /dev/cpuset $ROOT/dev/cpuset
mount --bind /dev/freezer $ROOT/dev/freezer
mount --bind /proc $ROOT/proc
mount --bind /sys $ROOT/sys
mount --bind /data $ROOT/data
mount --bind /system $ROOT/system
mount --bind /sdcard $ROOT/sdcard

mkdir -p /dev/shm
chmod 777 /dev/shm

mount -t tmpfs tmpfs $ROOT/run


# Put current process into freezer cgroup
echo "THAWED" > /dev/freezer/$ROOT/freezer.state
echo $$ > /dev/freezer/$ROOT/tasks

if [ ! -d "/dev/cpuset/big-aff" ]; then
    mkdir -p /dev/cpuset/big-aff
    echo "4-7" > /dev/cpuset/big-aff/cpus
    echo "0" > /dev/cpuset/big-aff/mems
fi

# Set CPU affinity to big cores only
echo $$ > /dev/cpuset/big-aff/tasks


export PATH=/bin:/usr/bin:/sbin
export LD_PRELOAD=
export LD_LIBRARY_PATH=


# Start daemons
chroot $ROOT /etc/init.d/dbus start
chroot $ROOT /etc/init.d/cron start
chroot $ROOT /etc/init.d/ssh start
chroot $ROOT /etc/init.d/x11-common start


# Fixes
chroot $ROOT sudo -i rm -f /tmp/.X0-lock || echo "ok"

chroot $ROOT sudo -i mkdir -p /run/user
chroot $ROOT sudo -i chown user:user /run/user
chroot $ROOT sudo -i chmod 0700 /run/user


# Exec user init script, or get shell
if [ -f $ROOT/home/user/init.sh ]; then
    chroot $ROOT sudo -i /home/user/init.sh
else
    chroot $ROOT sudo -u user -i bash
fi

