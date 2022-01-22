#!/bin/bash

source $(dirname $0)/build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

if [ -z $FDKAAC_PATH ]; then
    echo "please specify fdk-aac installed PATH"
    exit 1
else
    if [ ${FDKAAC_PATH:$((${#FDKAAC_PATH}-1))} != "/" ]; then
        FDKAAC_PATH=${FDKAAC_PATH}"/"
    fi
    LDFLAGS=$(env PKG_CONFIG_PATH=${FDKAAC_PATH}lib/pkgconfig pkg-config --libs-only-L fdk-aac)
    LDFLAGS=$LDFLAGS" -Wl,-rpath,"$(find ${FDKAAC_PATH} -name 'lib' | head -n1)
    CFLAGS=$(env PKG_CONFIG_PATH=${FDKAAC_PATH}lib/pkgconfig pkg-config --cflags fdk-aac)
fi

echo $LDFLAGS
echo $CFLAGS

FDKAAC_CLI_BUILD_PATH=${WORK_PATH}"/fdkaac-cli-build."$(date "+%Y%m%d%H%M%S.")$$"/"
FDKAAC_CLI_RELEASES_URL="https://github.com/nu774/fdkaac/releases"

fetch_github_releases $FDKAAC_CLI_RELEASES_URL $FDKAAC_CLI_BUILD_PATH

RESOURCE_URL=$(cat ${FDKAAC_CLI_BUILD_PATH}tarball_list | head -n1)
FDKAAC_CLI_VERSION=$(echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)')
FDKAAC_CLI_SRC=${FDKAAC_CLI_BUILD_PATH}"fdkaac-cli"${FDKAAC_VERSION}".tar.gz"

curl -Lso $FDKAAC_CLI_SRC $RESOURCE_URL
tar xf $FDKAAC_CLI_SRC -C $FDKAAC_CLI_BUILD_PATH

cd $FDKAAC_CLI_BUILD_PATH$(tar ft $FDKAAC_CLI_SRC | head -n1)
autoreconf -i
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" ./configure --prefix=${FDKAAC_CLI_BUILD_PATH}"fdkaac-cli"
make -j4
make install
