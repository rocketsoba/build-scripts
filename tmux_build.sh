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

TMUX_BUILD_PATH=${WORK_PATH}"/tmux-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $TMUX_BUILD_PATH ]; then
    mkdir -p $TMUX_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
TMUX_SRC=${TMUX_BUILD_PATH}"tmux-3.2a.tar.gz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/tmux"
fi

if !(find /usr/lib64/libevent.so -type l > /dev/null 2>&1); then
    echo "please install libevent"
    exit 1;
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="https://github.com/tmux/tmux/releases/download/3.2a/tmux-3.2a.tar.gz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $TMUX_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/tmux-3.2a.tar.gz" ]; then
        curl -Lso $CACHE_DIR"/tmux-3.2a.tar.gz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/tmux-3.2a.tar.gz" ${TMUX_SRC}
fi

tar xf $TMUX_SRC -C $TMUX_BUILD_PATH

cd $(find $TMUX_BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}"
make -j4
make install
echo $TMUX_BUILD_PATH
echo "{}" | jq '.name|="tmux"|.version|="3.2a"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $TMUX_BUILD_PATH
fi
