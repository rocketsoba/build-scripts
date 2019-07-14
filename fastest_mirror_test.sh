#!/usr/bin/env bash

source ./build_func.sh

GNU_URL_LIST=(
    "https://mirrors.ustc.edu.cn/gnu/"
    "https://mirrors.tuna.tsinghua.edu.cn/gnu/"
    "https://mirrors.sjtug.sjtu.edu.cn/gnu/"
    "https://mirrors.nju.edu.cn/gnu/"
    "https://mirror-hk.koddos.net/gnu/"
    "https://ftp.jaist.ac.jp/pub/GNU/"
    "https://mirror.jre655.com/GNU"
    "https://mirror.ossplanet.net/gnu/"
    "http://ftp.twaren.net/Unix/GNU/gnu/"
    "https://ftp.yzu.edu.tw/gnu/"
    "https://mirror.freedif.org/GNU/"
)

curl_multi_exec "${GNU_URL_LIST[@]}"
