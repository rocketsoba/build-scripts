#!/bin/bash

source ./build_func.sh

COMMANDS=("gcc" "curl" "sed" "grep" "autoreconf" "make" "libtool" "strip" "jq")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

MPC_BUILD_PATH=${WORK_PATH}"/mpc-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $MPC_BUILD_PATH ]; then
    mkdir -p $MPC_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
MPC_SRC=${MPC_BUILD_PATH}"mpc-0.8.1.tar.xz"
PREFIXPREFIX=${HOME}"/.opt"
PREFIX=${PREFIXPREFIX}"/mpc"

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

LDFLAGS="-L"${GMP_LIBRARY_PATH}" -Wl,-rpath,"${GMP_LIBRARY_PATH}" -L"${MPFR_LIBRARY_PATH}" -Wl,-rpath,"${MPFR_LIBRARY_PATH}" ${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="-I"${GMP_INCLUDE_PATH}" -I"${MPFR_INCLUDE_PATH}" ${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="http://ftp.jaist.ac.jp/pub/Linux/kernel.org/tools/crosstool/files/src/mpc-0.8.1.tar.xz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $MPC_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/mpc-0.8.1.tar.xz" ]; then
        curl -Lso $CACHE_DIR"/mpc-0.8.1.tar.xz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/mpc-0.8.1.tar.xz" ${MPC_SRC}
fi

tar xf $MPC_SRC -C $MPC_BUILD_PATH

cd $MPC_BUILD_PATH$(tar ft $MPC_SRC | head -n1)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}" --disable-static
make -j4
make install
echo $MPC_BUILD_PATH
echo "{}" | jq '.name|="mpc"|.version|="0.8.1"|.prefix|="'${PREFIX}'"|.libdir|="'${PREFIX}'/lib"|.includedir|="'${PREFIX}'/include"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $MPC_BUILD_PATH
fi
