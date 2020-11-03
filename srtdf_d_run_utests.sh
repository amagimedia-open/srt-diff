#!/bin/bash

#https://node-tap.org/tap-protocol/

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(dirname $(readlink -e $0))
BASENAME=$(basename $0)
BARENAME=${BASENAME%%.*}

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

export PATH=$PATH:$PWD
cd $DIRNAME

source common_bash_functions.sh
source common_tap_functions.sh
source srtdf_d_utest_common_functions.sh

tap_version

tap_plan `cat srtdf_d_utests_list.txt | wc -l`

echo "0" > $TMP1

cat srtdf_d_utests_list.txt |\
while read test_case_script_name
do
    if ! ./$test_case_script_name
    then
        echo "2" > $TMP1
    fi
done

echo ""
exit $(cat $TMP1)

