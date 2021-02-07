#!/bin/bash

#+--------------------------------------------------------------------------+
#| srt_diff usage notes                                                     |
#|                                                                          |
#| Lets say you have two srt files                                          |
#| (a) reference.srt    : the reference/original srt                        |
#| (b) transcribed.srt  : the srt that is the result of a transcription     |
#| and you want to compare how good the transcribed one is against the      |
#| original.                                                                |
#| The following steps must be followed:                                    |
#| (1) execute ./srtdf_h_build_rel_docker_image.sh                          |
#| (2) copy input files into a folder (say testdata). see (#COPYFILES)      |
#| (3) Map this folder into the /data folder and invoke srt_diff via        |
#|     a docker. see (#SRTDIFFINVOKE)                                       |
#| (4) Examine results. see (#EXAMINERESULTS)                               |
#| (5) Generate a histogram of the distances (#GENHIST)                     |
#+--------------------------------------------------------------------------+

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

#+-----------+
#| COPYFILES |
#+-----------+

H_TEST_FOLDER=$DIRNAME/testdata

mkdir -p $H_TEST_FOLDER

cp $DIRNAME/Ironman_1_1080i60.srt  $H_TEST_FOLDER
cp $DIRNAME/Ironman_sstt_withf.srt $H_TEST_FOLDER

#----[srt_diff.sh help]-------------------------------------------------------

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

#----[execute srt_diff.sh]---------------------------------------------------

#SRTDIFFINVOKE

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

#----[examine the results]---------------------------------------------------

#EXAMINERESULTS

read LEV_DIST SRTLEV_FILEPATH SRTCOMP_FILEPATH SRTCOMPLEV_FILEPATH <<< $(cat $TMP1)

cat <<EOD
Levenshtein distance = $LEV_DIST
Levenshtein details filepath = ${SRTLEV_FILEPATH/\/data/$H_TEST_FOLDER}
SRT comparison details filepath = ${SRTCOMP_FILEPATH/\/data/$H_TEST_FOLDER}
SRT comparison + Levenshtein details filepath = ${SRTCOMPLEV_FILEPATH/\/data/$H_TEST_FOLDER}
EOD

#----[generate histogram]----------------------------------------------------

#GENHIST

cat <<EOD >$H_TEST_FOLDER/rangespec.txt
BEGIN_I,END_E,NAME
0,500,0000-0500-ms
500,1000,0500-1000-ms
1000,2000,1000-2000-ms
2000,*,2000-****-ms
EOD
# note that you range-specification is optional as
# srtdf_lev_hist.sh provides a default

docker run                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $H_TEST_FOLDER:/data             \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srtdf_lev_hist.sh                   \
            -r /data/rangespec.txt          \
            /data/srtlev.csv > $H_TEST_FOLDER/srtlevhist.csv

echo "SRT Levenshtein histogram filepath = $H_TEST_FOLDER/srtlevhist.csv"

exit 0

