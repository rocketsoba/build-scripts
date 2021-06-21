#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip" "jq")
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

CACHE_DIR=$WORK_PATH"/src-cache"
GCC_SRC=${GCC_BUILD_PATH}"gcc-4.9.4.tar.bz2"
PREFIXPREFIX=${HOME}"/.opt"
PREFIX=${PREFIXPREFIX}"/gcc"

if !(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "gmp/package_info.json" > /dev/null 2>&1); then
    echo "please install gmp"
    exit 1;
else
    GMP_PATH=$(cat $(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "gmp/package_info.json" | head -n1) | jq -r '.prefix')
    GMP_LIBRARY_PATH=$(cat  ${GMP_PATH}"/package_info.json" | jq -r '.libdir')
    GMP_INCLUDE_PATH=$(cat  ${GMP_PATH}"/package_info.json" | jq -r '.includedir')
fi

if !(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "mpfr/package_info.json" > /dev/null 2>&1); then
    echo "please install mpfr"
    exit 1;
else
    MPFR_PATH=$(cat $(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "mpfr/package_info.json" | head -n1) | jq -r '.prefix')
    MPFR_LIBRARY_PATH=$(cat  ${MPFR_PATH}"/package_info.json" | jq -r '.libdir')
    MPFR_INCLUDE_PATH=$(cat  ${MPFR_PATH}"/package_info.json" | jq -r '.includedir')
fi

if !(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "mpc/package_info.json" > /dev/null 2>&1); then
    echo "please install mpc"
    exit 1;
else
    MPC_PATH=$(cat $(find ${PREFIXPREFIX} -maxdepth 2 -type f | grep "mpc/package_info.json" | head -n1) | jq -r '.prefix')
    MPC_LIBRARY_PATH=$(cat  ${MPC_PATH}"/package_info.json" | jq -r '.libdir')
    MPC_INCLUDE_PATH=$(cat  ${MPC_PATH}"/package_info.json" | jq -r '.includedir')
fi

LDFLAGS="-L"${GMP_LIBRARY_PATH}" -Wl,-rpath,"${GMP_LIBRARY_PATH}" -L"${MPFR_LIBRARY_PATH}" -Wl,-rpath,"${MPFR_LIBRARY_PATH}" -L"${MPC_LIBRARY_PATH}" -Wl,-rpath,"${MPC_LIBRARY_PATH}" ${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="-I"${GMP_INCLUDE_PATH}" -I"${MPFR_INCLUDE_PATH}" -I"${MPC_INCLUDE_PATH}" ${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

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
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ../configure --prefix="${PREFIX}" --disable-bootstrap --enable-languages=c,c++ --disable-multilib
make -j4
make install
echo $GCC_BUILD_PATH
echo "{}" | jq '.name|="gcc"|.version|="4.9.4"|.prefix|="'${PREFIX}'"|.libdir|="'${PREFIX}'/lib"|.includedir|="'${PREFIX}'/include"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

# https://ryuichi1208.hateblo.jp/entry/2020/05/11/000000_1
