#!/bin/bash

# https://chitoku.jp/programming/bash-getopts-long-options#--foo-bar-%E3%82%92%E5%87%A6%E7%90%86%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95
while getopts "a-:" OPT; do
    # OPTIND 番目の引数を optarg へ代入
    OPTARG2="${!OPTIND}"
    if [ "$OPT" = - ]; then
       OPT="${OPTARG}"
    fi

    case "$OPT" in
        prefixprefix)
            PREFIXPREFIX=$OPTARG2
            shift
            ;;
        prefix)
            PREFIX=$OPTARG2
            shift
            ;;
    esac
done
shift $((OPTIND - 1))

source $(dirname $0)/build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip" "jq")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

OPENSSL_BUILD_PATH=${WORK_PATH}"/openssl-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $OPENSSL_BUILD_PATH ]; then
    mkdir -p $OPENSSL_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
OPENSSL_SRC=${OPENSSL_BUILD_PATH}"/openssl-1.1.1m.tar.gz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/openssl"
fi

LDFLAGS=" -Wl,-rpath,${PREFIX}/lib ${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="https://www.openssl.org/source/openssl-1.1.1m.tar.gz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $OPENSSL_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/openssl-1.1.1m.tar.gz" ]; then
        curl -Lso $CACHE_DIR"/openssl-1.1.1m.tar.gz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/openssl-1.1.1m.tar.gz" ${OPENSSL_SRC}
fi

tar xf $OPENSSL_SRC -C $OPENSSL_BUILD_PATH

cd $(find $OPENSSL_BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./config --prefix="${PREFIX}" shared zlib
make -j4
make install
echo $OPENSSL_BUILD_PATH
echo "{}" | jq '.name|="openssl"|.version|="1.1.1m"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"


if [ -n $CLEAN_MODE ]; then
    rm -rf $OPENSSL_BUILD_PATH
fi
