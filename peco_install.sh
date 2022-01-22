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

PECO_WORK_PATH=${WORK_PATH}"/peco-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $PECO_WORK_PATH ]; then
    mkdir -p $PECO_WORK_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
PECO_SRC=${PECO_WORK_PATH}"peco_linux_amd64.tar.gz"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/peco"
fi

RESOURCE_URL="https://github.com/peco/peco/releases/download/v0.5.10/peco_linux_amd64.tar.gz"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $PECO_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/peco_linux_amd64.tar.gz" ]; then
        curl -Lso $CACHE_DIR"/peco_linux_amd64.tar.gz" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/peco_linux_amd64.tar.gz" ${PECO_SRC}
fi

tar xf $PECO_SRC -C $PECO_WORK_PATH
cd $(find $PECO_WORK_PATH -mindepth 1 -maxdepth 1 -type d)
if ! [ -d $PREFIX ]; then
    mkdir -p ${PREFIX}"/bin"
fi
cp peco ${PREFIX}"/bin"
echo $PECO_WORK_PATH
echo "{}" | jq '.name|="peco"|.version|="0.5.10"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $PECO_WORK_PATH
fi
