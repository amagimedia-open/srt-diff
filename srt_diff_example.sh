#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(readlink -e $(dirname $0))
BASENAME=$(basename $0)
DUMP_HELP=0
[[ ${1-""} = "-h" ]] && { DUMP_HELP=1; }

#----[temp files and termination]--------------------------------------------

function fnxOnEnd
{
    rm $TMP1 $TMP2
}

TMP1=`mktemp`
TMP2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[prepare data folder]---------------------------------------------------

H_TEST_FOLDER=$DIRNAME/testdata

mkdir -p $H_TEST_FOLDER

cp $DIRNAME/Ironman_1_1080i60.srt  $H_TEST_FOLDER
cp $DIRNAME/Ironman_sstt_withf.srt $H_TEST_FOLDER

#----[execute srt_diff.sh]---------------------------------------------------

if ((DUMP_HELP))
then
    docker run                                  \
            --rm                                \
            --privileged                        \
            --network host                      \
            --name srt-diff-rel-c               \
            -v $H_TEST_FOLDER:/data             \
            -w /srt-diff                        \
            srt-diff-rel                        \
            ./srt_diff.sh                       \
                -h
    exit 0
fi

docker run                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $H_TEST_FOLDER:/data             \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srt_diff.sh                       \
            -O /data/Ironman_1_1080i60.srt  \
            -T /data/Ironman_sstt_withf.srt \
    > $TMP1
RET=$?

if ((RET != 0))
then
    echo "srt_diff failed" >&2
    exit 3
fi

read LEV_DIST SRTLEV_FILEPATH SRTCOMP_FILEPATH SRTCOMPLEV_FILEPATH <<< $(cat $TMP1)

cat <<EOD
Levenshtein distance = $LEV_DIST
Levenshtein details filepath = ${SRTLEV_FILEPATH/\/data/$H_TEST_FOLDER}
SRT comparison details filepath = ${SRTCOMP_FILEPATH/\/data/$H_TEST_FOLDER}
SRT comparison + Levenshtein details filepath = ${SRTCOMPLEV_FILEPATH/\/data/$H_TEST_FOLDER}
EOD

cat ${SRTLEV_FILEPATH/\/data/$H_TEST_FOLDER} |\
docker run                                  \
        -i                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $H_TEST_FOLDER:/data             \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srt_lev_hist.sh

exit 0

