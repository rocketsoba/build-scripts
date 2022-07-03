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

COMMANDS=("curl" "sed" "grep" "jq" "php")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

COMPOSER_WORK_PATH=${WORK_PATH}"/composer-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $COMPOSER_WORK_PATH ]; then
    mkdir -p $COMPOSER_WORK_PATH
fi

CACHE_DIR=$WORK_PATH"/src-cache"
SRC_CACHE_MODE=1
CLEAN_MODE=1
COMPOSER_SRC=${COMPOSER_WORK_PATH}"composer-setup.php"

if [ -z $PREFIXPREFIX ]; then
    PREFIXPREFIX=${HOME}"/.opt"
fi
if [ -z $PREFIX ]; then
    PREFIX=${PREFIXPREFIX}"/composer"
fi

RESOURCE_URL="https://getcomposer.org/installer"
if [ -z $SRC_CACHE_MODE ]; then
    curl -Lso $COMPOSER_SRC $RESOURCE_URL
else
    if ! [ -d $CACHE_DIR ]; then
        mkdir -p $CACHE_DIR
    fi

    if ! [ -f $CACHE_DIR"/composer-setup.php" ]; then
        curl -Lso $CACHE_DIR"/composer-setup.php" $RESOURCE_URL
    fi
    cp ${CACHE_DIR}"/composer-setup.php" ${COMPOSER_SRC}
fi

if ! [ -d $PREFIX ]; then
    mkdir -p ${PREFIX}"/bin"
fi
php $COMPOSER_SRC --install-dir=${PREFIX}"/bin"
mv ${PREFIX}"/bin/composer.phar" ${PREFIX}"/bin/composer"
echo $COMPOSER_WORK_PATH
echo "{}" | jq '.name|="composer"|.version|="'$(${PREFIX}"/bin/composer" --version | grep -Po "(?<=version )[\.0-9]+(?= )")'"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"

if [ -n $CLEAN_MODE ]; then
    rm -rf $COMPOSER_WORK_PATH
fi
