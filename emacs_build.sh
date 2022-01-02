#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip" "jq")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

EMACS_BUILD_PATH=${WORK_PATH}"/emacs-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $EMACS_BUILD_PATH ]; then
    mkdir -p $EMACS_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
EMACS_SRC=${EMACS_BUILD_PATH}"emacs-27.2.tar.xz"
PREFIXPREFIX=${HOME}"/.opt"
PREFIX=${PREFIXPREFIX}"/emacs"

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="http://ftp.jaist.ac.jp/pub/GNU/emacs/emacs-27.2.tar.xz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $EMACS_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/emacs-27.2.tar.xz" ]; then
        curl -Lso $CACHE_DIR"/emacs-27.2.tar.xz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/emacs-27.2.tar.xz" ${EMACS_SRC}
fi

tar xf $EMACS_SRC -C $EMACS_BUILD_PATH

cd $(find $EMACS_BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}" --without-makeinfo
make -j4
make install
echo $EMACS_BUILD_PATH
echo "{}" | jq '.name|="emacs"|.version|="27.2"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $EMACS_BUILD_PATH
fi
