#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(readlink -e $(dirname $0))
BASENAME=$(basename $0)

#----[prepare data folder]---------------------------------------------------

mkdir -p $DIRNAME/testdata

cp $DIRNAME/Ironman_1_1080i60.srt  $DIRNAME/testdata
cp $DIRNAME/Ironman_sstt_withf.srt $DIRNAME/testdata

#----[execute srt_diff.sh]---------------------------------------------------

#-it \

docker run                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $DIRNAME/testdata:/data          \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srt_diff.sh                       \
            -O /data/Ironman_1_1080i60.srt  \
            -T /data/Ironman_sstt_withf.srt 


