#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

GMP_BUILD_PATH=${WORK_PATH}"/gcc4.9.4-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $GMP_BUILD_PATH ]; then
    mkdir -p $GMP_BUILD_PATH
fi

LDFLAGS="-Wl,-s -Wl,--gc-sections"
CFLAGS="-Os"
CXXFLAGS=$CFLAGS
CACHE_DIR=$WORK_PATH"/src-cache"
GMP_SRC=${GMP_BUILD_PATH}"gmp-4.3.2.tar.bz2"

RESOURCE_URL="http://ftp.yz.yamagata-u.ac.jp/pub/GNU/gmp/gmp-4.3.2.tar.bz2"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $GMP_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/gmp-4.3.2.tar.bz2" ]; then
        curl -Lso $CACHE_DIR"/gmp-4.3.2.tar.bz2" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/gmp-4.3.2.tar.bz2" ${GMP_SRC}
fi

tar xf $GMP_SRC -C $GMP_BUILD_PATH

cd $GMP_BUILD_PATH$(tar ft $GMP_SRC | head -n1)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix=${HOME}"/opt/gmp" --enable-cxx -disable-static
# ./configure --prefix=${GMP_BUILD_PATH}"gmp" -disable-static
make -j4
make install
echo $GMP_BUILD_PATH
