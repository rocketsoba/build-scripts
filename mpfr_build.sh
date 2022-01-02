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

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip" "jq")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

MPFR_BUILD_PATH=${WORK_PATH}"/mpfr-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $MPFR_BUILD_PATH ]; then
    mkdir -p $MPFR_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
MPFR_SRC=${MPFR_BUILD_PATH}"mpfr-2.4.2.tar.xz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/mpfr"
fi

if !(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "gmp/package_info.json" > /dev/null 2>&1); then
    echo "please install gmp"
    exit 1;
else
    GMP_PATH=$(cat $(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "gmp/package_info.json" | head -n1) | jq -r '.prefix')
    GMP_LIBRARY_PATH=$(cat  ${GMP_PATH}"/package_info.json" | jq -r '.libdir')
    GMP_INCLUDE_PATH=$(cat  ${GMP_PATH}"/package_info.json" | jq -r '.includedir')
fi

LDFLAGS="-L"${GMP_LIBRARY_PATH}" -Wl,-rpath,"${GMP_LIBRARY_PATH}" ${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="-I"${GMP_INCLUDE_PATH}" ${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

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
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}" --disable-static
make -j4
make install
echo $MPFR_BUILD_PATH
echo "{}" | jq '.name|="mpfr"|.version|="2.4.2"|.prefix|="'${PREFIX}'"|.libdir|="'${PREFIX}'/lib"|.includedir|="'${PREFIX}'/include"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $MPFR_BUILD_PATH
fi
