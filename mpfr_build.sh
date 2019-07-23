#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

MPFR_BUILD_PATH=${WORK_PATH}"/gcc4.9.4-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $MPFR_BUILD_PATH ]; then
    mkdir -p $MPFR_BUILD_PATH
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS
CACHE_DIR=$WORK_PATH"/src-cache"
MPFR_SRC=${MPFR_BUILD_PATH}"mpfr-2.4.2.tar.xz"



RESOURCE_URL="http://ftp.jaist.ac.jp/pub/GNU/mpfr/mpfr-2.4.2.tar.xz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $MPFR_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/mpfr-2.4.2.tar.xz" ]; then
        curl -Lso $CACHE_DIR"/mpfr-2.4.2.tar.xz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/mpfr-2.4.2.tar.xz" ${MPFR_SRC}
fi

tar xf $MPFR_SRC -C $MPFR_BUILD_PATH

cd $MPFR_BUILD_PATH$(tar ft $MPFR_SRC | head -n1)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix=${HOME}"/opt/mpfr" -disable-static
# ./configure --prefix=${MPFR_BUILD_PATH}"mpfr" -disable-static
make -j4
make install
echo $MPFR_BUILD_PATH

