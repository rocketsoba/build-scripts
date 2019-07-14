#!/usr/bin/env bash

fetch_github_releases () {
    # 引数の確認
    if [ $# -ne 2 ]; then
        echo "Usage: fetch_github_releases github_url target_path"
        exit 1
    fi
    local TARGET_URL=$1
    local TARGET_PATH=$2

    # URLの確認
    if !(echo $TARGET_URL | grep -P "^https\://github\.com/[^/]+/[^/]+/releases$" > /dev/null 2>&1); then
        echo "Given URL is invalid. This function only accepts github release page URL."
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
    curl -Lso ${TARGET_PATH}releases.html $TARGET_URL

    #リリースのHTMLが正しく取得で来てるか確認する
    if ! [ -s ${TARGET_PATH}releases.html ] || ! [ -e ${TARGET_PATH}releases.html ]; then
        echo "Fetch failed."
        exit 1
    fi

    grep -Po "(?<=class=\"muted-link\" href=\").+\.tar\.gz" ${TARGET_PATH}releases.html | xargs -I{} echo "https://github.com"{} > ${TARGET_PATH}tarball_list
    if ! [ -s ${TARGET_PATH}tarball_list ] || ! [ -e ${TARGET_PATH}tarball_list ]; then
        echo "Unable to find archive link elements. Html dom might be changed."
        exit 1
    fi

    echo "before while loop"

    while true
    do
        sleep 5
        local NEXT_URL=$(grep -Po "(?<=<a rel=\"nofollow\" href=\")[^\"]+(?=\">Next</a>)" ${TARGET_PATH}releases.html)

        if [ "${NEXT_URL}" = "" ]; then
            break
        fi

        if !(echo $NEXT_URL | grep -P "^https\://github\.com/[^/]+/[^/]+/releases" > /dev/null 2>&1); then
            echo "Pagination move failed"
            exit 1
        fi

        curl -Lso ${TARGET_PATH}releases.html $NEXT_URL

        #リリースのHTMLが正しく取得で来てるか確認する
        if ! [ -s ${TARGET_PATH}releases.html ] || ! [ -e ${TARGET_PATH}releases.html ]; then
            echo "Fetch failed."
            exit 1
        fi

        local RESULT=$(grep -Po "(?<=class=\"muted-link\" href=\").+\.tar\.gz" ${TARGET_PATH}releases.html | xargs -I{} echo "https://github.com"{})
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
            # exit 1
        else
            echo $command ok
        fi
    done
}

curl_multi_exec () {
    local url
    local count=0

    local emacs_binary_urls=()
    for url in "$@"; do
        env TIMEFORMAT='%R' bash -c 'echo '$url'; if ! [ -s '$count'.html ]; then time curl -fsLo '$count'.html '$url'; fi'
        # echo $count'.html'

        local emacs_url=$(search_href_and_fix "emacs" "${count}.html" $url 0)
        env TIMEFORMAT='%R' bash -c 'echo "'$emacs_url'"; if ! [ -s '$count'_emacs.html ]; then time curl -fsLo '$count'_emacs.html "'$emacs_url'"; fi'

        local emacs_binary=$(search_href_and_fix "emacs-26.2.tar.xz" "${count}_emacs.html" $emacs_url 1)
        emacs_binary_urls+=($emacs_binary)
        # echo $emacs_binary

        # env TIMEFORMAT='%R' timeout 10 bash -c 'time curl -r 0-5242879 -fsLo /dev/null '$emacs_binary
        echo $((count++)) > /dev/null
        # echo ""
    done

    for emacs_binary in ${emacs_binary_urls[@]}; do
        # env TIMEFORMAT='%R' timeout 10 bash -c 'time curl -r 0-5242879 -fLo /dev/null '$emacs_binary' && echo '$emacs_binary&
        local domain=$(echo $emacs_binary | grep -Po "https?://[A-Za-z0-9-\.]+")
        echo ${domain//./_}
    done
}

search_href_and_fix() {
    local search_str=$1
    local file_name=$2
    local url=$3
    local regex_mode=$4

    if [ $regex_mode -eq 1 ]; then
        local url_suffix=$(grep -Po "(?<=href=\")[^\"]*${search_str}(?=\")" $file_name | head -n1)
        # echo "absolute mode"
    else
        local url_suffix=$(grep -Po "(?<=href=\")[^\"]*${search_str}[^\"]*(?=\")" $file_name | head -n1)
    fi

    if [ "${url_suffix:0:2}" == "./" ]; then
        echo $url${url_suffix:2}
    elif [ "${url_suffix:0:1}" == "/" ]; then
        local url=$(echo $url | grep -Po "https?://[A-Za-z0-9-\.]+")
        echo $url$url_suffix
    else
        echo $url$url_suffix
    fi
}
