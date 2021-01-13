#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(dirname $(readlink -e $0))
BASENAME=$(basename $0)
BARENAME=${BASENAME%%.*}
UTESTNUM=${BARENAME##*_}
UTESTDESC="runs srt_diff.sh"

ORG_SRT_FILEPATH=$DIRNAME/Ironman_1_1080i60.srt
TRAN_SRT_FILEPATH=$DIRNAME/Ironman_sstt_withf.srt

GOLD_FILEPATH=$DIRNAME/srtdf_d_utest_07.gold.txt

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

cp $ORG_SRT_FILEPATH  /data
cp $TRAN_SRT_FILEPATH /data

tap_utest_begins

srt_diff.sh \
    -O /data/$(basename $ORG_SRT_FILEPATH)   \
    -T /data/$(basename $TRAN_SRT_FILEPATH)  \
    -d "/data/foo" \
    -p "utest07." > $TMP1

head -n 1 $TMP1 > $TMP2
for i in `cat $TMP1 | sed '1d'`
do
    echo "$i" | boxes -d stone | sed 's/^/#/' >> $TMP2
    cat $i >> $TMP2
done

cp $TMP2 $DIRNAME/$BARENAME.out
chmod go+r $DIRNAME/$BARENAME.out

if ! is_utest_output_ok $TMP2
then
    tap_utest_failed
    exit 1
fi

tap_utest_passed
exit 0

