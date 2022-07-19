#!/bin/sh
set -e

ROOT="yalcut"
VERSION="testing"

debootstrap --arch=arm64 --foreign $VERSION $ROOT http://ftp.nl.debian.org/debian
tar -czvf $ROOT.tar.gz setup.sh run.sh $ROOT

