#!/bin/bash

set -u
set -x

SSTT_FOLDER_IN_DK=/srt-diff

docker exec \
        -it \
        --privileged \
        -w $SSTT_FOLDER_IN_DK \
        srt-diff-dev-container \
        bash

