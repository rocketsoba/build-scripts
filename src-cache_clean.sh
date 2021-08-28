#!/bin/bash

if [ -z $TMP ]; then
    WORK_PATH="/tmp"
else
    WORK_PATH=$TMP
fi

CACHE_DIR=${WORK_PATH}'/src-cache'

if [ -d $CACHE_DIR ]; then
   rm -rf $CACHE_DIR
fi
