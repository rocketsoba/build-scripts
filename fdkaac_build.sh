#!/bin/bash

source $(dirname $0)/build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

FDKAAC_BUILD_PATH=${WORK_PATH}"/fdkaac-build."$(date "+%Y%m%d%H%M%S.")$$"/"
FDKAAC_RELEASES_URL="https://github.com/mstorsjo/fdk-aac/releases"

fetch_github_releases $FDKAAC_RELEASES_URL $FDKAAC_BUILD_PATH

RESOURCE_URL=$(cat ${FDKAAC_BUILD_PATH}tarball_list | head -n1)
FDKAAC_VERSION=$(echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)')
FDKAAC_SRC=${FDKAAC_BUILD_PATH}"fdk-aac-"${FDKAAC_VERSION}".tar.gz"

curl -Lso $FDKAAC_SRC $RESOURCE_URL
tar xf $FDKAAC_SRC -C $FDKAAC_BUILD_PATH

cd $FDKAAC_BUILD_PATH$(tar ft $FDKAAC_SRC | head -n1)
autoreconf -i
./configure --prefix=${FDKAAC_BUILD_PATH}"fdk-aac" --enable-static=no --enable-static=yes
make -j4
make install
