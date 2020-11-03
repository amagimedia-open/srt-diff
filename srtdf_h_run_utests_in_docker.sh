#!/bin/bash

set -u
#set -x

#+----------------------+
#| change the following |
#+----------------------+

SAMPLES_FOLDER_IN_HOST=$(readlink -e ../../../samples/bein_1)

#+-------------------------+
#| dont change from hereon |
#+-------------------------+

SSTT_FOLDER_IN_DK=/srt-diff

#xhost local:root
#xhost +

docker run \
        -it \
        --rm \
        --privileged \
        --network host \
        --name srt-diff-container \
        -v $PWD:$SSTT_FOLDER_IN_DK \
        -e COMMON_BASH_FUNCTIONS=$SSTT_FOLDER_IN_DK/common-bash-functions.sh \
        -w $SSTT_FOLDER_IN_DK \
        srt-diff \
        ./srtdf_d_run_utests.sh


# -v /tmp/.X11-unix:/tmp/.X11-unix \
# -e DISPLAY=$DISPLAY \
# -e "TZ=Asia/Kolkata" 

