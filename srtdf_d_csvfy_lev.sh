#!/bin/bash

set -u
#set -x

#----[globals]---------------------------------------------------------------

DIRNAME=$(dirname $(readlink -e $0))
BASENAME=$(basename $0)

#----[temp files and termination]--------------------------------------------

function fnxOnEnd
{
    rm $TMP1 $TMP2
}

TMP1=`mktemp`
TMP2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[main]-----------------------------------------------------------------

# This is a filter that takes the output of 
# python3 srtdf_srt_compare.py 
# on stdin and dumps csv on stdout

sed -n '/#--details--/,/#--metrics--/p' |\
sed '1d
     /^>/d
     /^</d
     $d
     /^[ \t]*$/d'


