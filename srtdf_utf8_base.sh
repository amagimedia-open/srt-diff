#!/bin/bash

set -u
#set -x

#----[temp files and termination]--------------------------------------------

TERMINATED=0

function fnxOnEnd
{
    ((TERMINATED==0)) && { rm -f $TMP1 $TMP2; }
    TERMINATED=1
}

TMP1=`mktemp`
TMP2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[globals]------------------------------------------------------------------------

DIRNAME=$(readlink -e $(dirname $0))
MODNAME=$(basename $0)

#----[sources]---------------------------------------------------------------

source $DIRNAME/common_bash_functions.sh

#----[options]---------------------------------------------------------------

OPT_SRT_FILEPATH=""

#----[helper functions]------------------------------------------------------

function usage
{
    cat <<EOD
NAME

    $MODNAME - Reduces an utf-8 srt file to its basic form
                   
SYNOPSIS

    $MODNAME [-h] srt_filepath
             
DETAILS

    This script performs the following
    (a) removes UTF-8 BOM at the beginning (only)
    (b) removes '\r' characters
    (c) removes lines starting with '#'
    (d) converts lines timing value from
        0000000:00:00,920 to 00:00:00,920
    on the specified srt_filepath and presents the output on stdout.

    This relies on the output of the 'file' command to check for 
    UTF-8 BOM magic number.

OPTIONS

    -h
       Displays this help and quits.
       This is optional.

EOD
}

#----------------------------------------------------------------------------
# MAIN
#----------------------------------------------------------------------------

#+---------------------+
#| argument processing |
#+---------------------+

TEMP=`getopt -o "h" -n "$0" -- "$@"`
eval set -- "$TEMP"

while true 
do
	case "$1" in
        -h) usage; exit 0;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [[ -z ${1-""} ]]
then
    error_message "srt_filepath not specified"
    exit 1
fi

OPT_SRT_FILEPATH=$1
if [[ ! -f $OPT_SRT_FILEPATH ]]
then
    error_message "$OPT_SRT_FILEPATH not present"
    exit 1
fi

#+---------------+
#| examine file  |
#+---------------+

UTF8_FILE=0
BOM_PRESENT=0

FILE_CONTENT=$(file $OPT_SRT_FILEPATH)

#info_message "$FILE_CONTENT"
#CR_PRESENT=0
#if [[ $FILE_CONTENT =~ CRLF ]]
#then
#    CR_PRESENT=1
#fi

if [[ $FILE_CONTENT =~ UTF-8 ]]
then
    UTF8_FILE=1
    if [[ $FILE_CONTENT =~ BOM ]]
    then
        BOM_PRESENT=1
    fi
fi

#+--------------+
#| process file |
#+--------------+


cat $OPT_SRT_FILEPATH |\
tr -d '\r' |\
(
    if ((BOM_PRESENT))
    then
        sed '1 s/\xEF\xBB\xBF//'
        # http://thegreyblog.blogspot.com/2010/09/shell-script-to-find-and-remove-bom.html
    else
        cat
    fi
) |\
(
    sed '
    /^#/d
    s/^0*\([0-9][0-9]\):/\1:/
    s/--> 0*\([0-9][0-9]\):/--> \1:/
    '
)

