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

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip" "jq" "nasm")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

X264BUILD_PATH=${WORK_PATH}"/x264-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $X264BUILD_PATH ]; then
    mkdir -p $X264BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
X264SRC=${X264BUILD_PATH}"x264"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/x264"
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="https://code.videolan.org/videolan/x264"
if [ -z $SRC_CACHE_MODE ]; then
    git clone --depth 1 --branch stable $RESOURCE_URL $X264SRC
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -d $CACHE_DIR"/x264" ]; then
        git clone --depth 1 --branch stable $RESOURCE_URL $CACHE_DIR"/x264"
    fi
    cp -r $CACHE_DIR"/x264" $X264SRC
fi

cd $(find $X264BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
GIT_REVISION=$(git --no-pager log HEAD --oneline | grep -Po "^[0-9a-z]+")
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}" --enable-shared
make -j4
make install
echo $X264BUILD_PATH
echo "{}" | jq '.name|="x264"|.version|="'${GIT_REVISION}'"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"


if [ -n $CLEAN_MODE ]; then
    rm -rf $X264BUILD_PATH
fi
