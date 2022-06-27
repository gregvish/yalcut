#!/bin/sh
set -e

ROOT="yalcut"
VERSION="jammy"

debootstrap --arch=arm64 --foreign $VERSION $ROOT http://ports.ubuntu.com/
tar -czvf $ROOT.tar.gz setup.sh init.sh run.sh $ROOT

