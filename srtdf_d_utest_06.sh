#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(dirname $(readlink -e $0))
BASENAME=$(basename $0)
BARENAME=${BASENAME%%.*}
UTESTNUM=${BARENAME##*_}
UTESTDESC="runs srtdf_csvfy_srt_lev.sh"

SRT_LEV_FILEPATH=$DIRNAME/srtdf_d_utest_05.gold.txt

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

cat $SRT_LEV_FILEPATH | srtdf_csvfy_srt_lev.sh > $TMP1

if ! is_utest_output_ok $TMP1
then
    tap_utest_failed
    exit 1
fi

tap_utest_passed
exit 0

