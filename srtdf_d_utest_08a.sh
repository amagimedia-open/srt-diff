#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(dirname $(readlink -e $0))
BASENAME=$(basename $0)
BARENAME=${BASENAME%%.*}
UTESTNUM=${BARENAME##*_}
UTESTDESC="runs srt_diff.sh"

IN_SRT_FILEPATH=$DIRNAME/srtdf_d_utest_08a_in.srt
GOLD_FILEPATH=$DIRNAME/srtdf_d_utest_08a.gold.srt

OUT_SRT_FILEPATH=$DIRNAME/$BARENAME.out.srt
DBG_SRT_FILEPATH=$DIRNAME/$BARENAME.dbg.csv

#----[temp files and termination]--------------------------------------------

function fnxOnEnd
{
    tap_utest_ends

    rm $TMP1 $TMP2 $IN_BASE_TMP
}

TMP1=`mktemp`
TMP2=`mktemp`
TMP3=`mktemp`
IN_BASE_TMP=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[main]-----------------------------------------------------------------

cd $DIRNAME
export PATH=$PATH:$PWD

source common_bash_functions.sh
source common_tap_functions.sh
source srtdf_d_utest_common_functions.sh

tap_utest_begins

rm -f $OUT_SRT_FILEPATH $DBG_SRT_FILEPATH

#+----------------------------+
#| run srtdf_infer_endtime.sh |
#+----------------------------+

srtdf_utf8_base.sh $IN_SRT_FILEPATH > $IN_BASE_TMP
cat $IN_BASE_TMP | srtdf_infer_endtime.sh -d >$TMP1 2>$TMP2

cp $TMP1 $OUT_SRT_FILEPATH
chmod +r $OUT_SRT_FILEPATH

cp $TMP2 $DBG_SRT_FILEPATH
chmod +r $DBG_SRT_FILEPATH

#+--------------------------------------------------------------+
#| check if there are differences in the index and phrase lines |
#+--------------------------------------------------------------+

sed '/ --> /d
     /^[ \t]*/d' $IN_BASE_TMP > $TMP1

sed '/ --> /d
     /^[ \t]*/d' $OUT_SRT_FILEPATH > $TMP2

diff $TMP1 $TMP2 > $TMP3
NUM_DIFF_LINES=`cat $TMP3 | wc -l`

if ((NUM_DIFF_LINES > 0))
then
    cat $TMP3 | sed 's/^/#/'
    tap_utest_failed
    exit 1
fi

if ! is_utest_output_ok $DBG_SRT_FILEPATH
then
    tap_utest_failed
    exit 1
fi

tap_utest_passed
exit 0

