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

VIM_BUILD_PATH=${WORK_PATH}"/vim-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $VIM_BUILD_PATH ]; then
    mkdir -p $VIM_BUILD_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
VIM_SRC=${VIM_BUILD_PATH}"vim-8.2.tar.bz2"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/vim"
fi

LDFLAGS="${LDFLAGS} -Wl,-s -Wl,--gc-sections"
CFLAGS="${CFLAGS} -Os"
CXXFLAGS=$CFLAGS

RESOURCE_URL="ftp://ftp.vim.org/pub/vim/unix/vim-8.2.tar.bz2"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $VIM_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/vim-8.2.tar.bz2" ]; then
        curl -Lso $CACHE_DIR"/vim-8.2.tar.bz2" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/vim-8.2.tar.bz2" ${VIM_SRC}
fi

tar xf $VIM_SRC -C $VIM_BUILD_PATH

cd $(find $VIM_BUILD_PATH -mindepth 1 -maxdepth 1 -type d)
cd src
env LDFLAGS="${LDFLAGS}" CFLAGS="${CFLAGS}" CXXFLAGS="${CXXFLAGS}" ./configure --prefix="${PREFIX}"
make -j4
make install
echo $VIM_BUILD_PATH
find $PREFIX -type f -name 'less.sh' -print0 | xargs -0 -I{} cp {} ${PREFIX}'/bin/'
echo "{}" | jq '.name|="vim"|.version|="8.2"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"


if [ -n $CLEAN_MODE ]; then
    rm -rf $VIM_BUILD_PATH
fi
