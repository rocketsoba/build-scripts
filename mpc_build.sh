#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

MPC_BUILD_PATH=${WORK_PATH}"/gcc4.9.4-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $MPC_BUILD_PATH ]; then
    mkdir -p $MPC_BUILD_PATH
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS
CACHE_DIR=$WORK_PATH"/src-cache"
MPC_SRC=${MPC_BUILD_PATH}"mpc-0.8.1.tar.xz"

RESOURCE_URL="http://ftp.jaist.ac.jp/pub/Linux/kernel.org/tools/crosstool/files/src/mpc-0.8.1.tar.xz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $MPC_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/mpc-0.8.1.tar.xz" ]; then
        curl -Lso $CACHE_DIR"/mpc-0.8.1.tar.xz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/mpc-0.8.1.tar.xz" ${MPC_SRC}
fi

tar xf $MPC_SRC -C $MPC_BUILD_PATH

cd $MPC_BUILD_PATH$(tar ft $MPC_SRC | head -n1)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix=${HOME}"/opt/mpc" --disable-static
make -j4
make install
echo $MPC_BUILD_PATH
