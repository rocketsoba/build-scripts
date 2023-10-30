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

COMMANDS=("curl" "sed" "grep" "jq")
check_neccessary_commands "${COMMANDS[@]}"

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

NVM_BUILD_PATH=${WORK_PATH}"/nvm-build."$(date "+%Y%m%d%H%M%S.")$$"/"
if ! [ -d $NVM_BUILD_PATH ]; then
    mkdir -p $NVM_BUILD_PATH
fi

NVM_TAGS_URL="https://github.com/nvm-sh/nvm/tags"
fetch_github_tags $NVM_TAGS_URL $NVM_BUILD_PATH

RESOURCE_URL=$(cat ${NVM_BUILD_PATH}tarball_list | head -n1)
NVM_VERSION=$(echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)')
NVM_SRC=${NVM_BUILD_PATH}"nvm-"${NVM_VERSION}".tar.gz"

if [ -z $PREFIX ]; then
    PREFIX=${HOME}"/.nvm"
fi

curl -Lso $NVM_SRC $RESOURCE_URL
tar xf $NVM_SRC -C $NVM_BUILD_PATH

cd $NVM_BUILD_PATH$(tar ft $NVM_SRC | head -n1)
env PROFILE=/dev/null ./install.sh
echo $NVM_BUILD_PATH
echo "{}" | jq '.name|="nvm"|.version|="'${NVM_VERSION}'"|.prefix|="'${PREFIX}'"|.install_date|="'"$(date -R)"'"' > ${PREFIX}"/package_info.json"
