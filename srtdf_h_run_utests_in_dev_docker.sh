#!/bin/bash

set -u
#set -x

SSTT_FOLDER_IN_DK=/srt-diff

docker run \
        -it \
        --rm \
        --privileged \
        --network host \
        --name srt-diff-dev-container \
        -v $PWD:$SSTT_FOLDER_IN_DK \
        -e COMMON_BASH_FUNCTIONS=$SSTT_FOLDER_IN_DK/common-bash-functions.sh \
        -w $SSTT_FOLDER_IN_DK \
        srt-diff-dev \
        ./srtdf_d_run_utests.sh

