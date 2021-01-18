#!/bin/bash

set -u
#set -x

#----[globals]------------------------------------------------------------------------

DIRNAME=$(readlink -e $(dirname $0))
MODNAME=$(basename $0)

G_MAPPED_ROOT_PATH=/data

#----[sources]---------------------------------------------------------------

source $DIRNAME/common_bash_functions.sh

#----[options]---------------------------------------------------------------

OPT_ORG_FILE_PATH=""
OPT_TRAN_FILE_PATH=""
OPT_INTERIM_FOLDER="$G_MAPPED_ROOT_PATH"
OPT_INTERIM_PREFIX=""
OPT_VERBOSE_MODE=0

#----[temp files and termination]--------------------------------------------

function fnxOnEnd
{
    rm $TMP1 $TMP2
}

TMP1=`mktemp`
TMP2=`mktemp`

trap 'fnxOnEnd;' 0 1 2 3 6 9 11

#----[helper functions]------------------------------------------------------

function usage
{
    cat <<EOD
NAME

    $MODNAME - Calculates levenshtein distance between two srt files
                   
SYNOPSIS

    $MODNAME -O original_srt_file_path
                -T transcribed_srt_file_path
                [-d interim_folder_path]
                [-p interim_files_prefix]
                [-h]
             
DESCRIPTION

    Calculates the levenshtein distance between the original_srt_file_path
    and transcribed_srt_file_path. The distance is echoed on stdout.

    The following interim files are generated by this script 

        (a) srt comparison between the two files
            this include index, time range, sentence and words
            of the two files
            {interim_files_prefix}srtcomp.txt

        (b) srt comparison (see (a)) with levenshtein details and distance
            {interim_files_prefix}srtcomplev.txt

        (c) levenshtein details in csv format
            {interim_files_prefix}srtlev.csv

    The file/folder paths specified for the -O, -T, and -d options 
    must have a common ancestor mapped to $G_MAPPED_ROOT_PATH using the 
    -v option of the docker run command.

OPTIONS

    -O $G_MAPPED_ROOT_PATH/.../original_srt_file_path
       the original/reference srt file.
       this is mandatory.

    -T $G_MAPPED_ROOT_PATH/.../transcribed_srt_file_path
       the srt file that is the result of a transcription session.
       (see ssttg and ssttg2 repositories).
       this is mandatory.

    -d $G_MAPPED_ROOT_PATH/.../interim_folder_path
       the folder in which the interim files are stored.
       this is optional. default is $OPT_INTERIM_FOLDER

    -p interim_files_prefix
       the prefix to be used for interim files.
       this is optional. default is '$OPT_INTERIM_PREFIX'

    -v 
       verbose mode. verbose messages are generated on stderr.
       this is optional.

    -h
        Displays this help and quits.
        This is optional.

EXAMPLES

    $MODNAME -O $G_MAPPED_ROOT_PATH/ref.srt -T $G_MAPPED_ROOT_PATH/tran.srt -d $G_MAPPED_ROOT_PATH/\$(date +%Y_%m_%d_%H_%M_%S_%N) -p "utest100."

EOD
}

#----------------------------------------------------------------------------
# MAIN
#----------------------------------------------------------------------------

export PATH=$PATH:$DIRNAME

#+---------------------+
#| argument processing |
#+---------------------+

TEMP=`getopt -o "O:T:d:p:fvh" -n "$0" -- "$@"`
eval set -- "$TEMP"

while true 
do
	case "$1" in
        -O) OPT_ORG_FILE_PATH="$2"; shift 2;;
        -T) OPT_TRAN_FILE_PATH="$2"; shift 2;;
        -d) OPT_INTERIM_FOLDER="$2"; shift 2;;
        -p) OPT_INTERIM_PREFIX="$2"; shift 2;;
        -v) OPT_VERBOSE_MODE=1; shift 1;;
        -h) usage; exit 0;;
		--) shift ; break ;;
		*) echo "Internal error!" ; exit 1 ;;
	esac
done

if [[ ! -d $G_MAPPED_ROOT_PATH ]]
then
    error_message "folder $G_MAPPED_ROOT_PATH not present"
    exit 1
fi

if [[ -n $OPT_ORG_FILE_PATH ]]
then
    if [[ ! -f $OPT_ORG_FILE_PATH ]]
    then
        error_message "file $OPT_ORG_FILE_PATH not present"
        exit 1
    fi
else
    error_message "-O option not specified"
    exit 1
fi

if [[ -n $OPT_TRAN_FILE_PATH ]]
then
    if [[ ! -f $OPT_TRAN_FILE_PATH ]]
    then
        error_message "file $OPT_TRAN_FILE_PATH not present"
        exit 1
    fi
else
    error_message "-T option not specified"
    exit 1
fi

create_folder $OPT_INTERIM_FOLDER ]]
if [[ ! -d $OPT_INTERIM_FOLDER ]]
then
    error_message "cannot find/create folder $OPT_INTERIM_FOLDER"
    exit 1
fi

if ((OPT_VERBOSE_MODE))
then
    info_message "OPT_ORG_FILE_PATH=$OPT_ORG_FILE_PATH"
    info_message "OPT_TRAN_FILE_PATH=$OPT_TRAN_FILE_PATH"
    info_message "OPT_INTERIM_FOLDER=$OPT_INTERIM_FOLDER"
    info_message "OPT_INTERIM_PREFIX=$OPT_INTERIM_PREFIX"
    info_message "OPT_VERBOSE_MODE=$OPT_VERBOSE_MODE"
fi

#+---------------------+
#| srt comp generation |
#+---------------------+

SRTCOMP_FILE_PATH="${OPT_INTERIM_FOLDER}/${OPT_INTERIM_PREFIX}srtcomp.txt"
if ! create_file $SRTCOMP_FILE_PATH
then
    exit 2
fi

cat $OPT_TRAN_FILE_PATH | grep -v '^#' > $TMP1

if ! python3 $DIRNAME/srtdf_srt_compare_writer.py \
                $OPT_ORG_FILE_PATH $TMP1 \
                > $SRTCOMP_FILE_PATH
then
    error_message "srt comparison generation failed"
    exit 2
fi

if ((OPT_VERBOSE_MODE))
then
    info_message "$SRTCOMP_FILE_PATH:srt comparison details"
fi


#+----------------------------------+
#| levenshtein details and distance |
#+----------------------------------+

SRTCOMPLEV_FILE_PATH="${OPT_INTERIM_FOLDER}/${OPT_INTERIM_PREFIX}srtcomplev.txt"
if ! create_file $SRTCOMPLEV_FILE_PATH
then
    exit 2
fi

DEBUG_OPTION=""
((OPT_VERBOSE_MODE)) && { DEBUG_OPTION=" -d "; }
cat $SRTCOMP_FILE_PATH |\
if ! python3 $DIRNAME/srtdf_srt_lev.py \
        $DEBUG_OPTION   \
        -l              \
        -C "ORG_TS,ORG_WORD,LEV_OP,TRAN_TS,TRAN_WORD,TS_DIFF" \
        > $SRTCOMPLEV_FILE_PATH 
then
    error_message "srt levenshtein generation failed"
    exit 2
fi

if ((OPT_VERBOSE_MODE))
then
    info_message "$SRTCOMPLEV_FILE_PATH:srt comparison and levenshtein details"
fi

#+-----------------------------------+
#| levenshtein details in csv format |
#+-----------------------------------+

SRTLEV_FILE_PATH="${OPT_INTERIM_FOLDER}/${OPT_INTERIM_PREFIX}srtlev.csv"
if ! create_file $SRTLEV_FILE_PATH
then
    exit 2
fi

cat $SRTCOMPLEV_FILE_PATH | srtdf_csvfy_srt_lev.sh > $SRTLEV_FILE_PATH

if ((OPT_VERBOSE_MODE))
then
    info_message "$SRTLEV_FILE_PATH:srt levenshtein details"
fi

#+--------+
#| result |
#+--------+

echo "$(head -n 1 $SRTCOMPLEV_FILE_PATH) $SRTLEV_FILE_PATH $SRTCOMP_FILE_PATH $SRTCOMPLEV_FILE_PATH"

