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

FFMPEG_BUILD_PATH=${WORK_PATH}"/ffmpeg-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $FFMPEG_BUILD_PATH ]; then
    mkdir -p $FFMPEG_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
FFMPEG_SRC=${FFMPEG_BUILD_PATH}"ffmpeg-6.0.tar.xz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/ffmpeg"
fi

if !(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "x264/package_info.json" > /dev/null 2>&1); then
    echo "please install x264"
    exit 1;
else
    X264_PATH=$(cat $(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "x264/package_info.json" | head -n1) | jq -r '.prefix')
    X264_PKGCONFIG_PATH=$(cat  ${X264_PATH}"/package_info.json" | jq -r '.prefix')"/lib/pkgconfig"
    X264_LIBRARY_PATH=$(cat  ${X264_PATH}"/package_info.json" | jq -r '.prefix')"/lib"
fi

if !(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "fdk-aac/package_info.json" > /dev/null 2>&1); then
    echo "please install fdk-aac"
    exit 1;
else
    FDKAAC_PATH=$(cat $(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "fdk-aac/package_info.json" | head -n1) | jq -r '.prefix')
    FDKAAC_PKGCONFIG_PATH=$(cat  ${FDKAAC_PATH}"/package_info.json" | jq -r '.prefix')"/lib/pkgconfig"
    FDKAAC_LIBRARY_PATH=$(cat  ${FDKAAC_PATH}"/package_info.json" | jq -r '.prefix')"/lib"
fi

LDFLAGS="${LDFLAGS} -Wl,-rpath,"${PREFIX}"/lib -Wl,-rpath,"${X264_LIBRARY_PATH}" -Wl,-rpath,"${FDKAAC_LIBRARY_PATH}" -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS
PKG_CONFIG_PATH=$X264_PKGCONFIG_PATH":"$FDKAAC_PKGCONFIG_PATH

RESOURCE_URL="https://ffmpeg.org/releases/ffmpeg-6.0.tar.xz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $FFMPEG_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/ffmpeg-6.0.tar.xz" ]; then
        curl -Lso $CACHE_DIR"/ffmpeg-6.0.tar.xz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/ffmpeg-6.0.tar.xz" ${FFMPEG_SRC}
fi

tar xf $FFMPEG_SRC -C $FFMPEG_BUILD_PATH

cd $(find $FFMPEG_BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
env PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}" --enable-gpl --enable-nonfree --enable-libx264 --enable-libfdk_aac --enable-shared
make -j4
make install
echo $FFMPEG_BUILD_PATH
echo "{}" | jq '.name|="ffmpeg"|.version|="6.0"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"


if [ -n $CLEAN_MODE ]; then
    rm -rf $FFMPEG_BUILD_PATH
fi
