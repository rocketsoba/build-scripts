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

FDKAAC_BUILD_PATH=${WORK_PATH}"/fdkaac-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $FDKAAC_BUILD_PATH ]; then
    mkdir -p $FDKAAC_BUILD_PATH
fi

FDKAAC_TAGS_URL="https://github.com/mstorsjo/fdk-aac/tags"
fetch_github_tags $FDKAAC_TAGS_URL $FDKAAC_BUILD_PATH

RESOURCE_URL=$(cat ${FDKAAC_BUILD_PATH}tarball_list | head -n1)
FDKAAC_VERSION=$(echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)')
FDKAAC_SRC=${FDKAAC_BUILD_PATH}"fdk-aac-"${FDKAAC_VERSION}".tar.gz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/fdk-aac"
fi

curl -Lso $FDKAAC_SRC $RESOURCE_URL
tar xf $FDKAAC_SRC -C $FDKAAC_BUILD_PATH

cd $FDKAAC_BUILD_PATH$(tar ft $FDKAAC_SRC | head -n1)
autoreconf -i
./configure --prefix="${PREFIX}" --enable-static=no --enable-static=yes
make -j4
make install
echo $FDKAAC_BUILD_PATH
echo "{}" | jq '.name|="fdkaac"|.version|="'${FDKAAC_VERSION}'"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"
