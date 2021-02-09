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

cp $DIRNAME/Ironman_1_1080i60.srt    $H_TEST_FOLDER
cp $DIRNAME/Ironman_sstt_withf.srt   $H_TEST_FOLDER
cp $DIRNAME/srtdf_d_utest_08c_in.srt $H_TEST_FOLDER

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
    echo "** srt_diff.sh failed" >&2
    exit 3
fi
echo "** srt_diff.sh succeeded" >&2

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

OUTPUT_FILEPATH=$H_TEST_FOLDER/srtlevhist.csv

docker run                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $H_TEST_FOLDER:/data             \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srtdf_lev_hist.sh                 \
            -r /data/rangespec.txt          \
            /data/srtlev.csv > $OUTPUT_FILEPATH
RET=$?

if ((RET != 0))
then
    echo "** srtdf_lev_hist.sh failed" >&2
    exit 3
fi
echo "** srtdf_lev_hist.sh succeeded" >&2

echo "SRT Levenshtein histogram filepath = $OUTPUT_FILEPATH"

#----[remove BOM and CRLF characters in a UTF-8 file]------------------------

OUTPUT_FILEPATH=$H_TEST_FOLDER/srtdf_d_utest_08c_in.stripped.srt

docker run                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $H_TEST_FOLDER:/data             \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srtdf_utf8_base.sh                \
            /data/srtdf_d_utest_08c_in.srt  \
        > $OUTPUT_FILEPATH
RET=$?

if ((RET != 0))
then
    echo "** srtdf_utf8_base.sh failed" >&2
    exit 3
fi
echo "** srtdf_utf8_base.sh succeeded" >&2

echo "Stripped UTF-8 filepath = $OUTPUT_FILEPATH"

#----[infer end time]--------------------------------------------------------

OUTPUT_FILEPATH=$H_TEST_FOLDER/srtdf_d_utest_08c_out.srt
DEBUG_FILEPATH=$H_TEST_FOLDER/srtdf_d_utest_08c_dbg.csv

cat $H_TEST_FOLDER/srtdf_d_utest_08c_in.stripped.srt |\
docker run                                  \
        -i                                  \
        --rm                                \
        --privileged                        \
        --network host                      \
        --name srt-diff-rel-c               \
        -v $H_TEST_FOLDER:/data             \
        -w /srt-diff                        \
        srt-diff-rel                        \
        ./srtdf_infer_endtime.sh            \
            -t 1300                         \
            -w 250                          \
            -d                              \
        1> $OUTPUT_FILEPATH                 \
        2> $DEBUG_FILEPATH
RET=$?

if ((RET != 0))
then
    echo "** srtdf_infer_endtime.sh failed" >&2
    exit 3
fi
echo "** srtdf_infer_endtime.sh succeeded" >&2

echo "End time inferred srt filepath = $OUTPUT_FILEPATH"
echo "End time inferred dbg filepath = $DEBUG_FILEPATH"

exit 0

