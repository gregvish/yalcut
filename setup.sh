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


# Deal with CONFIG_ANDROID_PARANOID_NETWORK thing (on android 10)
chroot $ROOT /bin/su -c "groupadd -g 3003 aid_inet"
chroot $ROOT /bin/su -c "groupadd -g 3004 aid_net_raw"
chroot $ROOT /bin/su -c "groupadd -g 3005 aid_admin"

chroot $ROOT /bin/su -c "usermod -a -G aid_inet,aid_net_raw,aid_admin root"


# Fix DNS
echo "nameserver 1.1.1.1" > $ROOT/etc/resolv.conf

# Fix sources.list
echo "deb http://ftp.nl.debian.org/debian testing main contrib non-free" \
    > $ROOT/etc/apt/sources.list
echo "deb-src http://ftp.nl.debian.org/debian testing main contrib non-free" \
    >> $ROOT/etc/apt/sources.list

# Make apt still work with the CONFIG_ANDROID_PARANOID_NETWORK thing
echo 'APT::Sandbox::User "root";' > $ROOT/etc/apt/apt.conf.d/01-android-nosandbox


chroot $ROOT /bin/su -c "apt update"
chroot $ROOT /bin/su -c "apt install sudo"


# Add regular user with sudo privs
echo "Creating user. Please input data"
chroot $ROOT /bin/sudo -i adduser user
chroot $ROOT /bin/sudo -i adduser user sudo
chroot $ROOT /bin/sudo -i usermod -a -G aid_inet,aid_net_raw,aid_admin user


# Install packages
PACKAGES="git tmux vim build-essential python3 htop openssh-server \
          fzf fd-find keychain locales \
          xvfb x11-xserver-utils libgles2-mesa-dev libxtst-dev libxdamage-dev \
          kitty dbus-x11 xfwm4 thunar synapse"

chroot $ROOT /bin/sudo -i apt install $PACKAGES

