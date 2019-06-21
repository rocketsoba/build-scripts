
# check neccessary commands
for command in curl sed grep; do
    if !(which $command > /dev/null 2>&1); then
        echo "please install "$command
        exit 1
    fi
done

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

FDKAAC_CLI_BUILD_PATH=${WORK_PATH}"/fdkaac-cli-build."`date "+%Y%m%d%H%M%S."`$$"/"
FDKAAC_CLI_RELEASES_URL="https://github.com/nu774/fdkaac/releases"

mkdir $FDKAAC_CLI_BUILD_PATH

curl -Lso ${FDKAAC_CLI_BUILD_PATH}fdkaac-cli_releases.html $FDKAAC_CLI_RELEASES_URL
#リリースのHTMLが正しく取得で来てるか確認する

cat ${FDKAAC_CLI_BUILD_PATH}fdkaac-cli_releases.html | grep -Po "(?<=class=\"muted-link\" href=\").+\.tar\.gz" | xargs -I{} echo "https://github.com"{} > ${FDKAAC_CLI_BUILD_PATH}tarball_list

while true
do
    FDKAAC_CLI_NEXT_URL=`cat ${FDKAAC_CLI_BUILD_PATH}fdkaac-cli_releases.html | grep -Po "(?<=<a rel=\"nofollow\" href=\")[^\"]+(?=\">Next</a>)"`
    echo $FDKAAC_CLI_NEXT_URL
    if [ "${FDKAAC_CLI_NEXT_URL}" = "" ]; then
        break
    fi
    sleep 3
    curl -Lso ${FDKAAC_CLI_BUILD_PATH}fdkaac-cli_releases.html $FDKAAC_CLI_NEXT_URL
    cat ${FDKAAC_CLI_BUILD_PATH}fdkaac-cli_releases.html | grep -Po "(?<=class=\"muted-link\" href=\").+\.tar\.gz" | xargs -I{} echo "https://github.com"{} >> ${FDKAAC_CLI_BUILD_PATH}tarball_list

    # if FDKAAC_CLI_NEXT_URL=`cat ${FDKAAC_CLI_BUILD_PATH}fdkaac-cli_releases.html | grep "Next" | grep -Po "(?<=href=\")[^\"]+"`; then
    #     echo $FDKAAC_CLI_NEXT_URL
    #     echo "Next Page exists"
    # fi
done

echo "抜けた"

RESOURCE_URL=`cat ${FDKAAC_CLI_BUILD_PATH}tarball_list | head -n1`
FDKAAC_CLI_VERSION=`echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)'`
echo $FDKAAC_CLI_VERSION
FDKAAC_CLI_SRC=${FDKAAC_CLI_BUILD_PATH}"fdkaac-cli"${FDKAAC_VERSION}".tar.gz"

curl -Lso $FDKAAC_CLI_SRC $RESOURCE_URL
tar xf $FDKAAC_CLI_SRC -C $FDKAAC_CLI_BUILD_PATH

cd $FDKAAC_CLI_BUILD_PATH`tar ft $FDKAAC_CLI_SRC | head -n1`
autoreconf -i
./configure --prefix=${FDKAAC_CLI_BUILD_PATH}"fdkaac-cli"
make -j4
make install
