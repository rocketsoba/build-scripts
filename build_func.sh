#!/usr/bin/env bash

fetch_github_tags () {
    # 引数の確認
    if [ $# -ne 2 ]; then
        echo "Usage: fetch_github_tags github_url target_path"
        exit 1
    fi
    local TARGET_URL=$1
    local TARGET_PATH=$2

    # URLの確認
    if !(echo $TARGET_URL | grep -P "^https\://github\.com/[^/]+/[^/]+/tags$" > /dev/null 2>&1); then
        echo "Given URL is invalid. This function only accepts github tag page URL."
        exit 1
    fi

    # パスの確認
    if [ ${TARGET_PATH:$((${#TARGET_PATH}-1))} != "/" ]; then
       TARGET_PATH=${TARGET_PATH}"/"
    fi
    if [ "${TARGET_PATH:0:5}" != "/tmp/" ]; then
        echo "Given PATH is invalid. Build path should be under \"/tmp\""
        exit 1
    fi
    # ディレクトリが存在しなければ生成
    if ! [ -d $TARGET_PATH ]; then
        mkdir -p $TARGET_PATH
    fi

    # リソースのHTMLを取得
    curl -Lso ${TARGET_PATH}tags.html $TARGET_URL

    #リリースのHTMLが正しく取得で来てるか確認する
    if ! [ -s ${TARGET_PATH}tags.html ] || ! [ -e ${TARGET_PATH}tags.html ]; then
        echo "Fetch failed."
        exit 1
    fi

    grep -Po "(?<=class=\"Link--muted\" href=\").+\.tar\.gz" ${TARGET_PATH}tags.html | xargs -I{} echo "https://github.com"{} > ${TARGET_PATH}tarball_list
    if ! [ -s ${TARGET_PATH}tarball_list ] || ! [ -e ${TARGET_PATH}tarball_list ]; then
        echo "Unable to find archive link elements. Html dom might be changed."
        exit 1
    fi

    echo "before while loop"

    while true
    do
        sleep 5
        local NEXT_URL=$(grep -Po "(?<=<a rel=\"nofollow\" href=\")[^\"]+(?=\">Next</a>)" ${TARGET_PATH}tags.html | xargs -I{} echo "https://github.com"{})

        if [ "${NEXT_URL}" = "" ]; then
            break
        fi

        echo $NEXT_URL
        if !(echo $NEXT_URL | grep -P "^https\://github\.com/[^/]+/[^/]+/tags" > /dev/null 2>&1); then
            echo "Pagination move failed"
            exit 1
        fi

        curl -Lso ${TARGET_PATH}tags.html $NEXT_URL

        #リリースのHTMLが正しく取得で来てるか確認する
        if ! [ -s ${TARGET_PATH}tags.html ] || ! [ -e ${TARGET_PATH}tags.html ]; then
            echo "Fetch failed."
            exit 1
        fi

        local RESULT=$(grep -Po "(?<=class=\"Link--muted\" href=\").+\.tar\.gz" ${TARGET_PATH}tags.html | xargs -I{} echo "https://github.com"{})
        if [ -z "${RESULT}" ]; then
            echo "Unable to find archive link elements. Html dom might be changed."
            exit 1
        else
            echo "${RESULT}" >> ${TARGET_PATH}tarball_list
        fi
    done
}

check_neccessary_commands () {
    local command cmd_list

    # 必要なコマンドが存在するか確認
    for command in "$@"; do
        echo checking $command ...
        if !(which $command > /dev/null 2>&1); then
            echo "please install "$command
            exit 1
        else
            echo $command ok
        fi
    done
}
