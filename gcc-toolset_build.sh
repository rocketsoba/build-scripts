#!/bin/bash

SCRIPT_PATH=$(dirname $0)
SCRIPT_LIST=(
    'gmp_build.sh'
    'mpfr_build.sh'
    'mpc_build.sh'
    'gcc4.9.4_build.sh'
)

for filename in ${SCRIPT_LIST[*]} ; do
    if ${SCRIPT_PATH}'/'${filename} > /dev/null 2>&1; then
        echo "successfully completed ${filename}..."
    else
        echo "error occured while installing ${filename}"
        exit 1
    fi
done




