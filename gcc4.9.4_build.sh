#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

GCC_BUILD_PATH=${WORK_PATH}"/gcc4.9.4-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $GCC_BUILD_PATH ]; then
    mkdir -p $GCC_BUILD_PATH
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS
CACHE_DIR=$WORK_PATH"/src-cache"
GCC_SRC=${GCC_BUILD_PATH}"gcc-4.9.4.tar.bz2"



RESOURCE_URL="https://ftp.yz.yamagata-u.ac.jp/pub/GNU/gcc/gcc-4.9.4/gcc-4.9.4.tar.bz2"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $GCC_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/gcc-4.9.4.tar.bz2" ]; then
        curl -Lso $CACHE_DIR"/gcc-4.9.4.tar.bz2" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/gcc-4.9.4.tar.bz2" ${GCC_SRC}
fi

tar xf $GCC_SRC -C $GCC_BUILD_PATH

cd $GCC_BUILD_PATH$(tar ft $GCC_SRC | head -n1)
mkdir build
cd build
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ../configure --prefix=${HOME}"/opt/gcc" --disable-bootstrap --enable-languages=c,c++ --disable-multilib
make -j4
make install
echo $GCC_BUILD_PATH
