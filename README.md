# yalcut
Yet Another Linux Chroot Under Termux

bootstrap.sh needs to be run on a debian machine, then the resulting tar.gz copied into termux

On termux:
    sudo bash ./setup.sh

Required before setup.sh:
    pkg install mount-utils

Good stuff after setup.sh:
    sudo dpkg-reconfigure locales
