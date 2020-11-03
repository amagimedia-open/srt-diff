#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(dirname $(readlink -e $0))
BASENAME=$(basename $0)
BARENAME=${BASENAME%%.*}
UTESTNUM=${BARENAME##*_}
UTESTDESC="runs srtdf_srt_compare.py"

SAMPLE_SRT_DIFF_FILEPATH=$DIRNAME/sample_srt_diff.txt

#----[temp files and termination]--------------------------------------------

function fnxOnEnd
{
    tap_utest_ends

    rm $TMP1 $TMP2
}

TMP1=`mktemp`
TMP2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[main]-----------------------------------------------------------------

cd $DIRNAME
export PATH=$PATH:$PWD

source common_bash_functions.sh
source common_tap_functions.sh
source srtdf_d_utest_common_functions.sh

tap_utest_begins

cat $SAMPLE_SRT_DIFF_FILEPATH |\
python3 srtdf_srt_compare.py \
        -l \
        -C "ORG_TS,ORG_WORD,LEV_OP,TRAN_TS,TRAN_WORD,TS_DIFF" \
        > $TMP1 2>&1

if ! is_utest_output_ok $TMP1
then
    tap_utest_failed
    exit 1
fi

tap_utest_passed
exit 0

