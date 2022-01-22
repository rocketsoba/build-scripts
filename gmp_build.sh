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

GMP_BUILD_PATH=${WORK_PATH}"/gmp-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $GMP_BUILD_PATH ]; then
    mkdir -p $GMP_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
GMP_SRC=${GMP_BUILD_PATH}"gmp-4.3.2.tar.bz2"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/gmp"
fi

LDFLAGS="-Wl,-s -Wl,--gc-sections"
CFLAGS="-Os"
CXXFLAGS=$CFLAGS

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
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}" --enable-cxx --disable-static
make -j4
make install
echo $GMP_BUILD_PATH
echo "{}" | jq '.name|="gmp"|.version|="4.3.2"|.prefix|="'${PREFIX}'"|.libdir|="'${PREFIX}'/lib"|.includedir|="'${PREFIX}'/include"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $GMP_BUILD_PATH
fi
