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

if [ -z $FDKAAC_PATH ]; then
    echo "please specify fdk-aac installed PATH"
    exit 1
else
    if [ ${FDKAAC_PATH:$((${#FDKAAC_PATH}-1))} != "/" ]; then
        FDKAAC_PATH=${FDKAAC_PATH}"/"
    fi
    LDFLAGS=$(env PKG_CONFIG_PATH=${FDKAAC_PATH}lib/pkgconfig pkg-config --libs-only-L fdk-aac)
    LDFLAGS=$LDFLAGS" -Wl,-rpath,"$(find ${FDKAAC_PATH} -name 'lib' | head -n1)
    CFLAGS=$(env PKG_CONFIG_PATH=${FDKAAC_PATH}lib/pkgconfig pkg-config --cflags fdk-aac)
fi

echo $LDFLAGS
echo $CFLAGS

FDKAAC_CLI_BUILD_PATH=${WORK_PATH}"/fdkaac-cli-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $FDKAAC_CLI_BUILD_PATH ]; then
    mkdir -p $FDKAAC_CLI_BUILD_PATH
fi

FDKAAC_CLI_TAGS_URL="https://github.com/nu774/fdkaac/tags"
fetch_github_tags $FDKAAC_CLI_TAGS_URL $FDKAAC_CLI_BUILD_PATH

RESOURCE_URL=$(cat ${FDKAAC_CLI_BUILD_PATH}tarball_list | head -n1)
FDKAAC_CLI_VERSION=$(echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)')
FDKAAC_CLI_SRC=${FDKAAC_CLI_BUILD_PATH}"fdkaac-cli"${FDKAAC_VERSION}".tar.gz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/fdkaac-cli"
fi

curl -Lso $FDKAAC_CLI_SRC $RESOURCE_URL
tar xf $FDKAAC_CLI_SRC -C $FDKAAC_CLI_BUILD_PATH

cd $FDKAAC_CLI_BUILD_PATH$(tar ft $FDKAAC_CLI_SRC | head -n1)
autoreconf -i
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" ./configure --prefix="${PREFIX}"
make -j4
make install
echo $FDKAAC_BUILD_PATH
echo "{}" | jq '.name|="fdkaac-cli"|.version|="'${FDKAAC_CLI_VERSION}'"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"
