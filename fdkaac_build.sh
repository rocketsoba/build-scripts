
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

FDKAAC_BUILD_PATH=${WORK_PATH}"/fdkaac-build."`date "+%Y%m%d%H%M%S."`$$"/"
FDKAAC_RELEASES_URL="https://github.com/mstorsjo/fdk-aac/releases"

mkdir $FDKAAC_BUILD_PATH

curl -Lso ${FDKAAC_BUILD_PATH}fdkaac_releases.html $FDKAAC_RELEASES_URL
#リリースのHTMLが正しく取得で来てるか確認する

cat ${FDKAAC_BUILD_PATH}fdkaac_releases.html | grep -Po "(?<=class=\"muted-link\" href=\").+\.tar\.gz" | xargs -I{} echo "https://github.com"{} > ${FDKAAC_BUILD_PATH}tarball_list
if cat ${FDKAAC_BUILD_PATH}fdkaac_releases.html | grep "Next" | grep -Po "(?<=href=\")[^\"]+"; then
    echo "Next Page exists"
fi

RESOURCE_URL=`cat ${FDKAAC_BUILD_PATH}tarball_list | head -n1`
FDKAAC_VERSION=`echo $RESOURCE_URL | grep -Po '(?<=/v)[^/]+(?=\.tar\.gz)'`
FDKAAC_SRC=${FDKAAC_BUILD_PATH}"fdk-aac-"${FDKAAC_VERSION}".tar.gz"

curl -Lso $FDKAAC_SRC $RESOURCE_URL
tar xf $FDKAAC_SRC -C $FDKAAC_BUILD_PATH

cd $FDKAAC_BUILD_PATH"/fdk-aac-"${FDKAAC_VERSION}
autoreconf -i
./configure --prefix=${FDKAAC_BUILD_PATH}"fdk-aac" --enable-static=no --enable-static=yes
make -j4
make install
