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

NASM_BUILD_PATH=${WORK_PATH}"/nasm-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $NASM_BUILD_PATH ]; then
    mkdir -p $NASM_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
NASM_SRC=${NASM_BUILD_PATH}"nasm-8.2.tar.bz2"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/nasm"
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="https://www.nasm.us/pub/nasm/releasebuilds/2.16/nasm-2.16.tar.xz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $NASM_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/nasm-2.16.tar.xz" ]; then
        curl -Lso $CACHE_DIR"/nasm-2.16.tar.xz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/nasm-2.16.tar.xz" ${NASM_SRC}
fi

tar xf $NASM_SRC -C $NASM_BUILD_PATH

cd $(find $NASM_BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}"
make -j4
make install
echo $NASM_BUILD_PATH
echo "{}" | jq '.name|="nasm"|.version|="2.16"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"


if [ -n $CLEAN_MODE ]; then
    rm -rf $NASM_BUILD_PATH
fi
