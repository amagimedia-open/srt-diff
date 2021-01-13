#!/bin/bash

set -u
set -x

DIRNAME=$(readlink -e $(dirname $0))
BASENAME=$(basename $0)

SSTT_FOLDER_IN_DK=/srt-diff

mkdir -p testdata

docker run \
        -it \
        --rm \
        --privileged \
        --network host \
        --name srt-diff-dev-container \
        -v $PWD:$SSTT_FOLDER_IN_DK \
        -v $DIRNAME/testdata:/data \
        -e COMMON_BASH_FUNCTIONS=$SSTT_FOLDER_IN_DK/common-bash-functions.sh \
        -w $SSTT_FOLDER_IN_DK \
        srt-diff-dev \
        bash

